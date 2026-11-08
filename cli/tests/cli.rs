use std::fs;
use std::process::Command;

fn binary() -> Command {
    Command::new(env!("CARGO_BIN_EXE_minflair"))
}

#[test]
fn help_lists_every_command() {
    let output = binary().arg("--help").output().expect("run minflair");
    assert!(output.status.success());

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("install"));
    assert!(stdout.contains("update"));
    assert!(stdout.contains("doctor"));
}

#[test]
fn version_is_printed() {
    let output = binary().arg("--version").output().expect("run minflair");
    assert!(output.status.success());

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains(env!("CARGO_PKG_VERSION")));
}

#[test]
fn doctor_fails_when_the_repository_is_missing() {
    let directory = tempfile::tempdir().expect("tempdir");
    let output = binary()
        .args(["doctor", "--json", "--repo"])
        .arg(directory.path())
        .env_remove("MINFLAIR_REPO")
        .env_remove("MINFLAIR_PREFS")
        .output()
        .expect("run minflair");

    assert_eq!(output.status.code(), Some(1));
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("\"repo\""));
    assert!(stdout.contains("\"failures\": 1"));
}

#[test]
fn install_forwards_flags_to_the_shell_script() {
    let directory = tempfile::tempdir().expect("tempdir");
    let manifest = directory.path().join("config/quickshell/components.tsv");
    fs::create_dir_all(manifest.parent().expect("parent")).expect("mkdir");
    fs::write(
        &manifest,
        "\
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell
",
    )
    .expect("write manifest");

    let arguments = directory.path().join("arguments.txt");
    let script = directory.path().join("install.sh");
    fs::write(
        &script,
        "#!/usr/bin/env bash\nprintf '%s\\n' \"$@\" > \"$MINFLAIR_TEST_ARGS\"\n",
    )
    .expect("write script");

    let output = binary()
        .args(["install", "--repo"])
        .arg(directory.path())
        .args(["--exclude", "kitty,nvim", "--dry-run", "--no-packages"])
        .env("MINFLAIR_TEST_ARGS", &arguments)
        .env_remove("MINFLAIR_REPO")
        .output()
        .expect("run minflair");

    assert!(output.status.success());
    let forwarded = fs::read_to_string(&arguments).expect("arguments");
    assert_eq!(
        forwarded,
        "--exclude\nkitty,nvim\n--dry-run\n--no-packages\n"
    );
}

#[test]
fn doctor_accepts_a_minimal_repository() {
    let directory = tempfile::tempdir().expect("tempdir");
    let manifest = directory.path().join("config/quickshell/components.tsv");
    std::fs::create_dir_all(manifest.parent().expect("parent")).expect("mkdir");
    std::fs::write(
        &manifest,
        "\
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell
hyprland\tHyprland\tcore\t1\tconfig/hypr\thyprland\t\t\t\tHyprland
",
    )
    .expect("write");
    std::fs::create_dir_all(directory.path().join("config/quickshell")).expect("mkdir");
    std::fs::create_dir_all(directory.path().join("config/hypr")).expect("mkdir");

    let prefs = directory.path().join("preferences.conf");
    let output = binary()
        .args(["doctor", "--json", "--repo"])
        .arg(directory.path())
        .env("MINFLAIR_PREFS", &prefs)
        .env_remove("MINFLAIR_REPO")
        .output()
        .expect("run minflair");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("\"name\": \"manifest\""));
    assert!(stdout.contains("2 components"));
    assert!(stdout.contains("\"name\": \"core components\""));
}
