import m from "mithril";

const Workspace = {
    list: [],
    _currentId: null,

    withWorkspace(cb) {
        if (!Workspace._currentId)
            Workspace._currentId = localStorage.getItem("conch.workspace");

        if (Workspace._currentId) return cb(Workspace._currentId);
        else return loadWorkspaces.then(currentId => cb(currentId));
    },

    async loadWorkspaces() {
        const workspaces = await m.request({
            method: "GET",
            url: "/workspace",
        });
        // Set to global workspace or first
        Workspace.list = workspaces;
        Workspace._currentId = (workspaces.find(w => w.name === "GLOBAL") ||
            workspace[0]
        ).id;
        localStorage.setItem("conch.workspace", Workspace._currentId);
        return Window._currentId;
    },
};

export default Workspace;
