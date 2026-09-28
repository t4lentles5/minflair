import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services
pragma Singleton

Item {
    id: githubService

    property string username: SettingsService.githubUsername
    property string token: SettingsService.githubToken
    property bool hasToken: false
    property string avatarUrl: ""
    property string fullName: ""
    property string bio: ""
    property string location: ""
    property int publicRepos: 0
    property int privateRepos: 0
    property int followers: 0
    property int totalStars: 0
    property int totalForks: 0
    property string topRepoName: "..."
    property string topRepoDesc: ""
    property int topRepoStars: 0
    property int topRepoForks: 0
    property string topRepoLang: ""
    property string joinedDate: "..."
    property int totalCommits: 0
    property string topLanguage: "None"
    property bool isFetching: false
    property var contributionData: []

    function fetchData() {
        debounceTimer.restart();
    }

    function getCleanToken() {
        if (!githubService.token)
            return "";

        return ("" + githubService.token).replace(/[\r\n\t\x00-\x1f\x7f-\xff\s]/g, "").trim();
    }

    function executeFetch() {
        let user = ("" + githubService.username).replace(/[\r\n\t\x00-\x1f\x7f-\xff\s]/g, "").trim();
        if (user === "") {
            githubService.hasToken = false;
            githubService.avatarUrl = "";
            githubService.fullName = "";
            githubService.bio = "";
            githubService.location = "";
            githubService.publicRepos = 0;
            githubService.privateRepos = 0;
            githubService.followers = 0;
            githubService.joinedDate = "...";
            githubService.totalStars = 0;
            githubService.totalForks = 0;
            githubService.topRepoName = "...";
            githubService.topRepoDesc = "";
            githubService.topRepoStars = 0;
            githubService.topRepoForks = 0;
            githubService.topRepoLang = "";
            githubService.topLanguage = "None";
            githubService.totalCommits = 0;
            githubService.contributionData = [];
            return ;
        }
        githubService.isFetching = true;
        fetchInfoProc.running = false;
        fetchInfoProc.running = true;
        fetchContributions(user);
    }

    function applyProfileData(profile) {
        if (!profile || !profile.login)
            return ;

        githubService.avatarUrl = profile.avatar_url || "";
        githubService.fullName = profile.name || "";
        githubService.bio = profile.bio || "";
        githubService.location = profile.location || "";
        githubService.publicRepos = profile.public_repos || 0;
        githubService.followers = profile.followers || 0;
        if (profile.created_at) {
            let date = new Date(profile.created_at);
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            githubService.joinedDate = months[date.getMonth()] + " " + date.getFullYear();
        }
    }

    function applyReposData(repos) {
        if (Array.isArray(repos)) {
            let starsSum = 0;
            let forksSum = 0;
            let maxStars = -1;
            let bestRepoName = "";
            let bestRepoDesc = "";
            let bestRepoStars = 0;
            let bestRepoForks = 0;
            let bestRepoLang = "";
            let langCounts = {
            };
            for (let i = 0; i < repos.length; i++) {
                let r = repos[i];
                if (!r)
                    continue;

                starsSum += r.stargazers_count || 0;
                forksSum += r.forks_count || 0;
                if (r.stargazers_count > maxStars) {
                    maxStars = r.stargazers_count;
                    bestRepoName = r.name;
                    bestRepoDesc = r.description || "";
                    bestRepoStars = r.stargazers_count || 0;
                    bestRepoForks = r.forks_count || 0;
                    bestRepoLang = r.language || "";
                }
                if (r.language)
                    langCounts[r.language] = (langCounts[r.language] || 0) + 1;

            }
            githubService.totalStars = starsSum;
            githubService.totalForks = forksSum;
            githubService.topRepoName = bestRepoName || "None";
            githubService.topRepoDesc = bestRepoDesc;
            githubService.topRepoStars = bestRepoStars;
            githubService.topRepoForks = bestRepoForks;
            githubService.topRepoLang = bestRepoLang;
            let mostLang = "None";
            let maxLangCount = 0;
            for (let lang in langCounts) {
                if (langCounts[lang] > maxLangCount) {
                    maxLangCount = langCounts[lang];
                    mostLang = lang;
                }
            }
            githubService.topLanguage = mostLang;
        }
    }

    function fetchContributions(user) {
        contribProc.running = false;
        contribProc.running = true;
    }

    function checkFetchingComplete() {
        fetchTimer.restart();
    }

    onUsernameChanged: fetchData()
    onTokenChanged: fetchData()

    Process {
        id: fetchInfoProc

        command: {
            let user = ("" + githubService.username).trim();
            let tok = ("" + githubService.token).replace(/[\r\n\t\x00-\x1f\x7f-\xff\s]/g, "").trim();
            if (tok !== "")
                return ["python3", Quickshell.shellDir + "/Core/Services/scripts/fetch_github_info.py", user, tok];

            return ["python3", Quickshell.shellDir + "/Core/Services/scripts/fetch_github_info.py", user];
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                try {
                    let parsed = JSON.parse(fetchInfoOutput.text);
                    if (parsed.profile) {
                        githubService.hasToken = parsed.hasToken === true;
                        applyProfileData(parsed.profile);
                        if (githubService.hasToken)
                            githubService.privateRepos = parsed.profile.total_private_repos || parsed.profile.owned_private_repos || 0;
                        else
                            githubService.privateRepos = 0;
                    }
                    if (parsed.repos)
                        applyReposData(parsed.repos);

                    if (parsed.commits && parsed.commits.total_count !== undefined)
                        githubService.totalCommits = parsed.commits.total_count;
                    else
                        githubService.totalCommits = 0;
                } catch (e) {
                    console.error("Github fetch error: " + e);
                }
            }
            checkFetchingComplete();
        }

        stdout: StdioCollector {
            id: fetchInfoOutput
        }

    }

    Process {
        id: contribProc

        command: {
            let user = ("" + githubService.username).trim();
            let tok = ("" + githubService.token).replace(/[\r\n\t\x00-\x1f\x7f-\xff\s]/g, "").trim();
            if (tok !== "")
                return ["python3", Quickshell.shellDir + "/Core/Services/scripts/fetch_github_contributions.py", user, tok];

            return ["python3", Quickshell.shellDir + "/Core/Services/scripts/fetch_github_contributions.py", user];
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                try {
                    let parsed = JSON.parse(contribOutput.text);
                    if (Array.isArray(parsed) && parsed.length > 0)
                        githubService.contributionData = parsed;

                } catch (e) {
                    console.error("Contributions parse error: " + e);
                }
            }
            checkFetchingComplete();
        }

        stdout: StdioCollector {
            id: contribOutput
        }

    }

    Timer {
        id: debounceTimer

        interval: 200
        repeat: false
        onTriggered: githubService.executeFetch()
    }

    Timer {
        id: fetchTimer

        interval: 500
        repeat: false
        onTriggered: githubService.isFetching = false
    }

    Timer {
        interval: 600000
        running: githubService.username !== ""
        repeat: true
        onTriggered: githubService.fetchData()
    }

}
