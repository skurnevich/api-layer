//The following configuration is a sample that can be used when releasing the plugin. If it won't be used, it needs to be removed.
module.exports = {
    branches: [
        {
            name: "master",
            level: "minor"
        },
        {
            name: "zowe-v?-lts",
            level: "patch"
        }
        // {
        //     name: "next",
        //     prerelease: true
        // }
    ],
    plugins: [
        "@octorelease/changelog",
        ["@octorelease/npm", {
            aliasTags: {
                "latest": ["zowe-v2-lts", "next"]
            },
            smokeTest: true
        }],
        ["@octorelease/github", {
            checkPrLabels: true
        }],
        "@octorelease/git"
    ]
};
