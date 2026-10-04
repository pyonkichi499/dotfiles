"""claude-sandbox の docker を使わない部分のテスト

実行: uv run --with pytest pytest ~/dotfiles/claude-sandbox/tests
"""

import hashlib
import importlib.machinery
import importlib.util
import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "claude-sandbox"
_loader = importlib.machinery.SourceFileLoader("claude_sandbox", str(SCRIPT))
_spec = importlib.util.spec_from_loader("claude_sandbox", _loader)
cs = importlib.util.module_from_spec(_spec)
sys.modules["claude_sandbox"] = cs  # dataclass がモジュールを引けるように
_loader.exec_module(cs)


@pytest.fixture(autouse=True)
def isolated_home(tmp_path, monkeypatch):
    home = tmp_path / "home"
    home.mkdir()
    monkeypatch.setenv("HOME", str(home))
    monkeypatch.delenv("XDG_STATE_HOME", raising=False)
    monkeypatch.delenv("XDG_CONFIG_HOME", raising=False)
    monkeypatch.delenv("CLAUDE_SANDBOX_IMAGE", raising=False)
    monkeypatch.setenv("GIT_CONFIG_GLOBAL", "/dev/null")
    monkeypatch.setenv("GIT_CONFIG_NOSYSTEM", "1")
    return home


def run_git(*args, cwd):
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


@pytest.fixture
def repo_dir(tmp_path):
    path = tmp_path / "work" / "my repo"
    path.mkdir(parents=True)
    run_git("init", "-q", "-b", "main", cwd=path)
    run_git("config", "user.name", "Tester", cwd=path)
    run_git("config", "user.email", "tester@example.com", cwd=path)
    run_git("commit", "-q", "--allow-empty", "-m", "init", cwd=path)
    return path


def write_host_config(home: Path, text: str) -> None:
    path = home / ".config" / "claude-sandbox" / "config.toml"
    path.parent.mkdir(parents=True)
    path.write_text(text)


# ---------- 引数 ----------

class TestParseCli:
    def test_no_args_runs_claude(self):
        assert cs.parse_cli([]) == cs.Cli("run")

    def test_unknown_options_go_to_claude(self):
        cli = cs.parse_cli(["--image", "img", "--dry-run", "-p", "hi", "-h"])
        assert (cli.command, cli.image, cli.dry_run, cli.claude_args) == ("run", "img", True, ["-p", "hi", "-h"])

    def test_double_dash_stops_parsing(self):
        assert cs.parse_cli(["--image=img", "--", "--dry-run"]).claude_args == ["--dry-run"]

    def test_help(self):
        assert cs.parse_cli(["-h"]).command == "help"
        assert cs.parse_cli(["shell", "--help"]).command == "help"
        assert cs.parse_cli(["help"]).command == "help"

    def test_subcommand_options(self):
        assert cs.parse_cli(["clean", "-y"]).yes
        assert cs.parse_cli(["build", "--no-cache"]).no_cache
        assert cs.parse_cli(["shell", "--image", "x", "--dry-run"]) == cs.Cli("shell", image="x", dry_run=True)

    @pytest.mark.parametrize("argv", [
        ["--image"],
        ["--image="],
        ["--dry-run=1"],
        ["build", "--image", "x"],
        ["doctor", "extra"],
        ["clean", "--dry-run"],
    ])
    def test_errors(self, argv):
        with pytest.raises(cs.SandboxError):
            cs.parse_cli(argv)


# ---------- リポジトリ ----------

class TestRepo:
    @pytest.mark.parametrize(("common", "name"), [
        ("/w/my repo/.git", "my_repo"),
        ("/srv/foo.git", "foo"),
        (None, "none"),
    ])
    def test_name(self, common, name):
        assert cs.Repo(Path("/w"), Path("/w"), Path(common) if common else None).name == name

    def test_state_dir_matches_bash_version(self, isolated_home):
        repo = cs.Repo(Path("/w/a b"), Path("/w/a b"), None)
        digest = hashlib.sha256(b"/w/a b").hexdigest()[:8]
        assert repo.state_dir == isolated_home / ".local" / "state" / "claude-sandbox" / f"a_b-{digest}"

    def test_detect_from_subdir(self, repo_dir):
        sub = repo_dir / "src"
        sub.mkdir()
        repo = cs.detect_repo(sub)
        assert (repo.workdir, repo.mount_root, repo.git_common_dir, repo.name) == (
            sub, repo_dir, repo_dir / ".git", "my_repo")

    def test_detect_worktree_uses_main_repo(self, repo_dir, tmp_path):
        wt = tmp_path / "wt"
        run_git("worktree", "add", "-q", str(wt), cwd=repo_dir)
        repo = cs.detect_repo(wt)
        assert (repo.mount_root, repo.git_common_dir, repo.name) == (wt, repo_dir / ".git", "my_repo")

    def test_refuses_home(self, isolated_home):
        with pytest.raises(cs.SandboxError, match="丸ごと"):
            cs.detect_repo(isolated_home)

    def test_outside_git(self, tmp_path):
        d = tmp_path / "plain"
        d.mkdir()
        repo = cs.detect_repo(d)
        assert (repo.mount_root, repo.git_common_dir) == (d, None)


# ---------- 設定ファイル ----------

class TestSettings:
    def test_repo_settings(self, repo_dir):
        (repo_dir / ".claude-sandbox.toml").write_text('image = "img"\n[env]\nFOO = "bar"\n')
        settings = cs.load_repo_settings(cs.detect_repo(repo_dir))
        assert (settings.image, settings.env, settings.mounts) == ("img", {"FOO": "bar"}, [])

    def test_repo_settings_reject_mounts(self, repo_dir):
        (repo_dir / ".claude-sandbox.toml").write_text('mounts = [{ source = "/tmp", target = "/x" }]\n')
        with pytest.raises(cs.SandboxError, match="ホスト側の設定"):
            cs.load_repo_settings(cs.detect_repo(repo_dir))

    @pytest.mark.parametrize("env", ["OTEL_FOO", "HOME", "GIT_AUTHOR_NAME", "CLAUDE_CODE_OAUTH_TOKEN"])
    def test_reserved_env(self, env):
        with pytest.raises(cs.SandboxError, match="claude-sandbox が設定する"):
            cs.parse_settings({"env": {env: "x"}}, "t", allow_mounts=False)

    @pytest.mark.parametrize("data", [
        {"image": ""},
        {"image": 1},
        {"env": {"1BAD": "x"}},
        {"env": {"FOO": 1}},
        {"env": "FOO=1"},
        {"unknown": 1},
    ])
    def test_invalid(self, data):
        with pytest.raises(cs.SandboxError):
            cs.parse_settings(data, "t", allow_mounts=False)

    def test_broken_toml(self, repo_dir):
        (repo_dir / ".claude-sandbox.toml").write_text("image = \n")
        with pytest.raises(cs.SandboxError, match="TOML"):
            cs.load_repo_settings(cs.detect_repo(repo_dir))

    def test_host_settings_match_by_path(self, repo_dir, isolated_home, tmp_path):
        data = isolated_home / "data"
        data.mkdir()
        write_host_config(isolated_home, f"""
["/somewhere/else"]
image = "other"

["{repo_dir}"]
image = "mine"
mounts = [
  {{ source = "~/data", target = "/data" }},
  {{ source = "~/data", target = "/data-rw", readonly = false }},
]
""")
        settings = cs.load_host_settings(cs.detect_repo(repo_dir))
        assert settings.image == "mine"
        assert settings.mounts == [cs.Mount(data, "/data", True), cs.Mount(data, "/data-rw", False)]

    def test_host_settings_tilde_key(self, isolated_home):
        repo_dir = isolated_home / "work" / "r"
        repo_dir.mkdir(parents=True)
        run_git("init", "-q", cwd=repo_dir)
        write_host_config(isolated_home, '["~/work/r"]\nimage = "x"\n')
        assert cs.load_host_settings(cs.detect_repo(repo_dir)).image == "x"

    def test_host_settings_without_section(self, repo_dir, isolated_home):
        write_host_config(isolated_home, '["/other"]\nimage = "x"\n')
        assert cs.load_host_settings(cs.detect_repo(repo_dir)) == cs.Settings()

    @pytest.mark.parametrize(("mount", "match"), [
        ('{ source = "~/nope", target = "/x" }', "ありません"),
        ('{ source = "relative", target = "/x" }', "絶対パス"),
        ('{ source = "~", target = "/x" }', "丸ごと"),
        ('{ source = "/tmp", target = "/home/sandbox" }', "target"),
        ('{ source = "/tmp", target = "/etc/claude-code/x" }', "target"),
        ('{ source = "/tmp", target = "x" }', "target"),
        ('{ source = "/tmp" }', "source, target"),
        ('{ source = "/tmp", target = "/x", readonly = "no" }', "真偽値"),
    ])
    def test_invalid_mounts(self, repo_dir, isolated_home, mount, match):
        write_host_config(isolated_home, f'["{repo_dir}"]\nmounts = [{mount}]\n')
        with pytest.raises(cs.SandboxError, match=match):
            cs.load_host_settings(cs.detect_repo(repo_dir))

    def test_host_config_inside_repo_is_refused(self, repo_dir, monkeypatch):
        monkeypatch.setenv("XDG_CONFIG_HOME", str(repo_dir / "cfg"))
        with pytest.raises(cs.SandboxError, match="書き換えられる"):
            cs.load_host_settings(cs.detect_repo(repo_dir))

    def test_image_precedence(self):
        host, repo = cs.Settings(image="host"), cs.Settings(image="repo")
        env = {"CLAUDE_SANDBOX_IMAGE": "env"}
        assert cs.resolve_image("cli", env, host, repo) == ("cli", "--image")
        assert cs.resolve_image(None, env, host, repo)[0] == "env"
        assert cs.resolve_image(None, {}, host, repo)[0] == "host"
        assert cs.resolve_image(None, {}, cs.Settings(), repo)[0] == "repo"
        assert cs.resolve_image(None, {}, cs.Settings(), cs.Settings()) == ("claude-sandbox", "既定")


# ---------- git ----------

class TestGit:
    def test_identity(self, repo_dir):
        assert cs.git_identity(repo_dir) == {
            "GIT_AUTHOR_NAME": "Tester", "GIT_COMMITTER_NAME": "Tester",
            "GIT_AUTHOR_EMAIL": "tester@example.com", "GIT_COMMITTER_EMAIL": "tester@example.com",
        }

    @pytest.mark.parametrize(("hooks_path", "writable"), [
        (None, False),
        (".husky", True),
        ("{root}/.githooks", True),
        ("{root}/.git/hooks", False),  # 読み取り専用で重ねるので問題ない
        ("/usr/share/hooks", False),
    ])
    def test_writable_hooks_path(self, repo_dir, hooks_path, writable):
        if hooks_path:
            run_git("config", "core.hooksPath", hooks_path.format(root=repo_dir), cwd=repo_dir)
        assert (cs.writable_hooks_path(cs.detect_repo(repo_dir)) is not None) == writable


# ---------- docker run の引数 ----------

def make_plan(repo, **overrides):
    values = dict(
        repo=repo, image="img", settings=cs.Settings(), otel=False, git_env={},
        tty=False, term="xterm", colorterm=None, user="1000:1000",
    )
    return cs.Plan(**(values | overrides))


def mounts_of(args):
    return [args[i + 1] for i, a in enumerate(args) if a == "--mount"]


class TestDockerRunArgs:
    def test_basic(self, repo_dir, isolated_home):
        repo = cs.detect_repo(repo_dir)
        args = cs.docker_run_args(make_plan(repo), ["claude", "-p", "hi"])
        assert args[:2] == ["docker", "run"]
        assert args[-4:] == ["img", "claude", "-p", "hi"]
        assert "-i" in args and "-it" not in args
        mounts = mounts_of(args)
        git_dir = repo_dir / ".git"
        assert f"type=bind,source={repo_dir},target={repo_dir}" in mounts
        assert f"type=bind,source={repo.state_dir},target=/home/sandbox" in mounts
        assert f"type=bind,source={git_dir}/config,target={git_dir}/config,readonly" in mounts
        assert f"type=bind,source={git_dir}/hooks,target={git_dir}/hooks,readonly" in mounts
        assert any(m.endswith("target=/etc/claude-code/CLAUDE.md,readonly") for m in mounts)
        assert any(m.endswith("target=/etc/claude-code/managed-settings.json,readonly") for m in mounts)
        assert ["--env-file", str(isolated_home / ".claude-sandbox.env")] == args[args.index("--env-file"):][:2]
        assert not any(a.startswith("OTEL_") for a in args)
        assert "claude-sandbox.repo=my_repo" in args

    def test_worktree_mounts_common_git_dir(self, repo_dir, tmp_path):
        wt = tmp_path / "wt"
        run_git("worktree", "add", "-q", str(wt), cwd=repo_dir)
        mounts = mounts_of(cs.docker_run_args(make_plan(cs.detect_repo(wt)), ["claude"]))
        git_dir = repo_dir / ".git"
        assert f"type=bind,source={git_dir},target={git_dir}" in mounts
        # 読み取り専用の重ね合わせは、親のマウントより後ろにないと効かない
        assert mounts.index(f"type=bind,source={git_dir}/config,target={git_dir}/config,readonly") > \
            mounts.index(f"type=bind,source={git_dir},target={git_dir}")

    def test_settings_otel_and_identity(self, repo_dir):
        settings = cs.Settings(env={"FOO": "a b"}, mounts=[cs.Mount(Path("/data"), "/d")])
        plan = make_plan(cs.detect_repo(repo_dir), settings=settings, otel=True, tty=True, colorterm="truecolor",
                         git_env={"GIT_AUTHOR_NAME": "T"})
        args = cs.docker_run_args(plan, ["bash"])
        assert "type=bind,source=/data,target=/d,readonly" in mounts_of(args)
        for env in ("FOO=a b", "GIT_AUTHOR_NAME=T", "COLORTERM=truecolor", "OTEL_RESOURCE_ATTRIBUTES=git.repo=my_repo",
                    "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://langfuse-otel-collector:4318/v1/traces"):
            assert env in args
        assert str(cs.OTEL_ENV_FILE) in args
        assert "-it" in args

    def test_no_git(self, tmp_path):
        d = tmp_path / "plain"
        d.mkdir()
        mounts = mounts_of(cs.docker_run_args(make_plan(cs.detect_repo(d)), ["claude"]))
        assert not any(".git" in m for m in mounts)


class TestSkills:
    def test_mounts_linked_skills(self, isolated_home, repo_dir):
        agents = isolated_home / ".agents" / "skills"
        for name in ("alpha", "no-skill-md"):
            (agents / name).mkdir(parents=True)
        (agents / "alpha" / "SKILL.md").write_text("---\nname: alpha\n---\n")
        skills = isolated_home / ".claude" / "skills"
        (skills / "synced" / "x").mkdir(parents=True)
        (skills / "synced" / "x" / "SKILL.md").write_text("")
        (skills / "alpha").symlink_to("../../.agents/skills/alpha")
        (skills / "no-skill-md").symlink_to("../../.agents/skills/no-skill-md")

        assert cs.skill_mounts() == [cs.Mount(agents / "alpha", "/home/sandbox/.claude/skills/alpha")]
        mounts = mounts_of(cs.docker_run_args(make_plan(cs.detect_repo(repo_dir)), ["claude"]))
        assert f"type=bind,source={agents}/alpha,target=/home/sandbox/.claude/skills/alpha,readonly" in mounts

    def test_no_skills_dir(self):
        assert cs.skill_mounts() == []


class TestHostMountpoints:
    def test_home_and_repo_targets(self, isolated_home, repo_dir, tmp_path):
        agents = isolated_home / ".agents" / "skills" / "alpha"
        agents.mkdir(parents=True)
        (agents / "SKILL.md").write_text("")
        (isolated_home / ".claude" / "skills").mkdir(parents=True)
        (isolated_home / ".claude" / "skills" / "alpha").symlink_to(agents)
        data_file = tmp_path / "data.txt"
        data_file.write_text("")
        repo = cs.detect_repo(repo_dir)
        settings = cs.Settings(mounts=[
            cs.Mount(tmp_path, "/home/sandbox/cache"),
            cs.Mount(data_file, f"{repo_dir}/data.txt"),
            cs.Mount(tmp_path, "/data"),  # コンテナ内だけのパスは作らない
        ])
        assert cs.host_mountpoints(make_plan(repo, settings=settings)) == [
            (repo.state_dir / ".claude" / "skills" / "alpha", True),
            (repo.state_dir / "cache", True),
            (repo_dir / "data.txt", False),
        ]
