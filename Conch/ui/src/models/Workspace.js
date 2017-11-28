import m from "mithril";

const Workspace = {
    list: [],

    withWorkspace(cb) {
        const currentId = Workspace.getCurrentId();
        if (currentId && Workspace.list.length) cb(currentId);
        else
            Workspace.loadWorkspaces().then(id => {
                cb(id);
            });
    },

    setCurrentId(workspaceId) {
        localStorage.setItem("conch.workspace", workspaceId);
    },

    getCurrentId() {
        return localStorage.getItem("conch.workspace");
    },

    loadWorkspaces() {
        return m
            .request({
                method: "GET",
                url: "/workspace",
            })
            .then(workspaces => {
                Workspace.list = workspaces;
                let currentId = Workspace.getCurrentId();
                if (!currentId || workspaces.findIndex(w => w.id === currentId) === -1) {
                    // Set to global workspace or first in the list
                    currentId = (workspaces.find(w => w.name === "GLOBAL") ||
                        workspaces[0]
                    ).id;
                    Workspace.setCurrentId(currentId);
                }
                return currentId;
            });
    },
};

export default Workspace;
