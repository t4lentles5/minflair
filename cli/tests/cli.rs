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
    assert!(stdout.contains("components"));
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
    let report: serde_json::Value = serde_json::from_str(&stdout).expect("doctor JSON");
    let checks = report["checks"].as_array().expect("checks");
    let repo = checks
        .iter()
        .find(|check| check["name"] == "repo")
        .expect("repo check");

    assert_eq!(repo["status"], "fail");
    assert!(report["summary"]["failures"].as_u64().expect("failures") >= 1);
}

#[test]
fn install_dry_run_keeps_preferences_untouched() {
    let directory = tempfile::tempdir().expect("tempdir");
    let manifest = directory.path().join("config/quickshell/components.tsv");
    fs::create_dir_all(manifest.parent().expect("parent")).expect("mkdir");
    fs::write(
        &manifest,
        "\
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell
hyprland\tHyprland\tcore\t1\tconfig/hypr\thyprland\t\t\t\thyprland
kitty\tKitty terminal\tterminal\t0\tconfig/kitty\tkitty\tkitty\tkitty\t\tTerminal
",
    )
    .expect("write manifest");
    for path in ["quickshell", "hypr", "kitty"] {
        fs::create_dir_all(directory.path().join("config").join(path)).expect("mkdir");
    }

    let home = directory.path().join("home");
    fs::create_dir_all(&home).expect("mkdir home");
    let prefs = home.join(".config/minflair/preferences.conf");
    let helper = home.join(".config/minflair/aur-helper");

    let output = binary()
        .args(["install", "--repo"])
        .arg(directory.path())
        .args([
            "--exclude",
            "kitty",
            "--dry-run",
            "--no-input",
            "--no-packages",
        ])
        .env("HOME", &home)
        .env("MINFLAIR_PREFS", &prefs)
        .env("MINFLAIR_AUR_HELPER_FILE", &helper)
        .env("TERM", "dumb")
        .env("NO_COLOR", "1")
        .env("COLUMNS", "100")
        .env_remove("MINFLAIR_REPO")
        .env_remove("MINFLAIR_AUR_HELPER")
        .output()
        .expect("run minflair");

    assert!(
        output.status.success(),
        "stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Dry run complete."));
    assert!(stdout.contains("Skipped (1):"));
    assert!(stdout.contains("Kitty terminal"));
    assert!(stdout.contains("[dry-run] would copy config/quickshell"));
    assert!(!prefs.exists(), "dry-run must not write preferences");
    assert!(!helper.exists(), "dry-run must not write the AUR helper");
    assert!(
        !home.join("install_errors.log").exists(),
        "dry-run must not write the error log"
    );
}

#[test]
fn update_dry_run_uses_the_native_pipeline() {
    let directory = tempfile::tempdir().expect("tempdir");
    let manifest = directory.path().join("config/quickshell/components.tsv");
    fs::create_dir_all(manifest.parent().expect("parent")).expect("mkdir");
    fs::write(
        &manifest,
        "\
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell
hyprland\tHyprland\tcore\t1\tconfig/hypr\thyprland\t\t\t\thyprland
kitty\tKitty terminal\tterminal\t0\tconfig/kitty\tkitty\tkitty\tkitty\t\tTerminal
",
    )
    .expect("write manifest");
    for path in ["quickshell", "hypr", "kitty"] {
        fs::create_dir_all(directory.path().join("config").join(path)).expect("mkdir");
    }
    fs::create_dir_all(directory.path().join("etc")).expect("mkdir");
    fs::write(directory.path().join("etc/sddm.conf"), "[Theme]\n").expect("write sddm");
    fs::write(directory.path().join("packages.txt"), "kitty\n").expect("write packages");
    fs::write(directory.path().join("packages-aur.txt"), "# none\n").expect("write aur packages");

    let home = directory.path().join("home");
    fs::create_dir_all(home.join(".config/quickshell")).expect("mkdir home");
    let prefs = home.join(".config/minflair/preferences.conf");
    let helper = home.join(".config/minflair/aur-helper");

    let output = binary()
        .args(["update", "--repo"])
        .arg(directory.path())
        .args([
            "--exclude",
            "kitty",
            "--dry-run",
            "--no-input",
            "--no-packages",
        ])
        .env("HOME", &home)
        .env("MINFLAIR_PREFS", &prefs)
        .env("MINFLAIR_AUR_HELPER_FILE", &helper)
        .env("TERM", "dumb")
        .env("NO_COLOR", "1")
        .env("COLUMNS", "100")
        .env_remove("MINFLAIR_REPO")
        .env_remove("MINFLAIR_AUR_HELPER")
        .env_remove("HYPRLAND_INSTANCE_SIGNATURE")
        .output()
        .expect("run minflair");

    assert!(
        output.status.success(),
        "stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Minflair updater"));
    assert!(stdout.contains("Dry run complete."));
    assert!(stdout.contains("Skipped (1):"));
    assert!(stdout.contains("Kitty terminal"));
    assert!(stdout.contains("[dry-run] would copy config/quickshell"));
    assert!(!stdout.contains("delegating update"));
    assert!(!prefs.exists(), "dry-run must not write preferences");
    assert!(!helper.exists(), "dry-run must not write the AUR helper");
    assert!(
        !home.join("install_errors.log").exists(),
        "dry-run must not write the error log"
    );
}

#[test]
fn update_requires_an_existing_install() {
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
    fs::create_dir_all(directory.path().join("config/quickshell")).expect("mkdir");
    fs::write(directory.path().join("packages.txt"), "quickshell\n").expect("write packages");
    fs::write(directory.path().join("packages-aur.txt"), "\n").expect("write aur packages");

    let home = directory.path().join("home");
    fs::create_dir_all(&home).expect("mkdir home");

    let output = binary()
        .args(["update", "--repo"])
        .arg(directory.path())
        .args(["--dry-run", "--no-input", "--no-packages"])
        .env("HOME", &home)
        .env("TERM", "dumb")
        .env("NO_COLOR", "1")
        .env_remove("MINFLAIR_REPO")
        .env_remove("MINFLAIR_PREFS")
        .env_remove("MINFLAIR_AUR_HELPER")
        .output()
        .expect("run minflair");

    assert_eq!(output.status.code(), Some(1));
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("Quickshell config not found"));
}

fn component_repository() -> tempfile::TempDir {
    let directory = tempfile::tempdir().expect("tempdir");
    let manifest = directory.path().join("config/quickshell/components.tsv");
    fs::create_dir_all(manifest.parent().expect("parent")).expect("mkdir");
    fs::write(
        &manifest,
        "\
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell
hyprland\tHyprland\tcore\t1\tconfig/hypr\thyprland\t\t\t\tHyprland
kitty\tKitty terminal\tterminal\t0\tconfig/kitty\tkitty\tkitty\tkitty\t\tTerminal
nvim\tNeovim\tterminal\t0\tconfig/nvim\tnvim\tnvim\t\t\tEditor
",
    )
    .expect("write manifest");
    directory
}

#[test]
fn components_manage_the_saved_selection() {
    let directory = component_repository();
    let home = directory.path().join("home");
    fs::create_dir_all(&home).expect("mkdir home");
    let prefs = home.join(".config/minflair/preferences.conf");

    let run = |args: &[&str]| {
        let mut command = binary();
        command
            .arg("components")
            .args(args)
            .args(["--repo"])
            .arg(directory.path())
            .env("HOME", &home)
            .env("MINFLAIR_PREFS", &prefs)
            .env("TERM", "dumb")
            .env("NO_COLOR", "1")
            .env_remove("MINFLAIR_REPO");
        command.output().expect("run minflair")
    };

    let output = run(&["list", "--json"]);
    assert!(
        output.status.success(),
        "stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let report: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("list JSON");
    let components = report["components"].as_array().expect("components");
    assert_eq!(components.len(), 4);
    assert!(components
        .iter()
        .all(|component| component["enabled"] == true));

    // A stale preferences file from an older release must not break the save.
    fs::create_dir_all(prefs.parent().expect("parent")).expect("mkdir prefs");
    fs::write(&prefs, "ghost\nobsolete\n").expect("write stale preferences");

    let output = run(&["disable", "kitty,nvim"]);
    assert!(
        output.status.success(),
        "stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("ghost"));
    assert!(stderr.contains("obsolete"));
    assert!(String::from_utf8_lossy(&output.stdout).contains("minflair update"));
    let saved = fs::read_to_string(&prefs).expect("preferences");
    assert!(saved.lines().any(|line| line.trim() == "kitty"));
    assert!(saved.lines().any(|line| line.trim() == "nvim"));
    assert!(!saved.lines().any(|line| line.trim() == "ghost"));

    let output = run(&["list", "--disabled", "--json"]);
    let report: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("list JSON");
    let ids: Vec<&str> = report["components"]
        .as_array()
        .expect("components")
        .iter()
        .map(|component| component["id"].as_str().expect("id"))
        .collect();
    assert_eq!(ids, ["kitty", "nvim"]);

    let output = run(&["enable", "kitty"]);
    assert!(output.status.success());
    assert!(String::from_utf8_lossy(&output.stdout).contains("minflair update"));
    let saved = fs::read_to_string(&prefs).expect("preferences");
    assert!(!saved.lines().any(|line| line.trim() == "kitty"));

    let output = run(&["reset"]);
    assert!(output.status.success());
    assert!(String::from_utf8_lossy(&output.stdout).contains("minflair update"));
    let saved = fs::read_to_string(&prefs).expect("preferences");
    assert!(!saved
        .lines()
        .any(|line| !line.trim().is_empty() && !line.trim().starts_with('#')));

    let output = run(&["disable", "quickshell"]);
    assert_eq!(output.status.code(), Some(1));
    assert!(String::from_utf8_lossy(&output.stderr).contains("core component cannot be disabled"));
}

#[test]
fn components_apply_requires_an_install() {
    let directory = component_repository();
    let home = directory.path().join("home");
    fs::create_dir_all(&home).expect("mkdir home");
    let prefs = home.join(".config/minflair/preferences.conf");

    let output = binary()
        .args(["components", "disable", "kitty", "--apply", "--repo"])
        .arg(directory.path())
        .env("HOME", &home)
        .env("MINFLAIR_PREFS", &prefs)
        .env("TERM", "dumb")
        .env("NO_COLOR", "1")
        .env_remove("MINFLAIR_REPO")
        .output()
        .expect("run minflair");

    assert_eq!(output.status.code(), Some(1));
    assert!(String::from_utf8_lossy(&output.stderr).contains("Quickshell config not found"));
    assert!(!String::from_utf8_lossy(&output.stdout).contains("Run `minflair update`"));
    assert!(fs::read_to_string(&prefs)
        .expect("preferences")
        .lines()
        .any(|line| line.trim() == "kitty"));
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

#[test]
fn doctor_warns_when_the_config_version_differs_from_the_binary() {
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

    // A configuration from a different release than the binary.
    let constants = directory
        .path()
        .join("config/quickshell/Core/Constants.qml");
    std::fs::create_dir_all(constants.parent().expect("parent")).expect("mkdir");
    std::fs::write(
        &constants,
        "Item {\n    readonly property string appVersion: \"0.0.1\"\n}\n",
    )
    .expect("write");

    let prefs = directory.path().join("preferences.conf");
    let output = binary()
        .args(["doctor", "--json", "--repo"])
        .arg(directory.path())
        .env("MINFLAIR_PREFS", &prefs)
        .env_remove("MINFLAIR_REPO")
        .output()
        .expect("run minflair");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let report: serde_json::Value = serde_json::from_str(&stdout).expect("doctor JSON");
    let checks = report["checks"].as_array().expect("checks");
    let version = checks
        .iter()
        .find(|check| check["name"] == "version")
        .expect("version check");

    assert_eq!(version["status"], "warn");
    assert!(version["detail"]
        .as_str()
        .expect("detail")
        .contains("out of date"));
}
