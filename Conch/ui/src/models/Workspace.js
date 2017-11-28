import m from "mithril";

const Workspace = {
    list: [],
    _currentId: null,

    withWorkspace(cb) {
        if (Workspace._currentId) cb(Workspace._currentId);
        else
            Workspace.loadWorkspaces().then(currentId => {
                cb(currentId);
            });
    },
    loadWorkspaces() {
        return m
            .request({
                method: "GET",
                url: "/workspace",
            })
            .then(workspaces => {
                Workspace.list = workspaces;
                // Set to global workspace or first
                Workspace._currentId = (workspaces.find(
                    w => w.name === "GLOBAL"
                ) || workspaces[0]
                ).id;
                return Workspace._currentId;
            });
    },
};

export default Workspace;
