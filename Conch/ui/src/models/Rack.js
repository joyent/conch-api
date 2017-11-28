import m from "mithril";

import Workspace from "./Workspace";

const Rack = {
    // Associative array of room names to list of racks
    rackRooms: {},
    loadRooms(workspaceId) {
        return m
            .request({
                method: "GET",
                url: `/workspace/${workspaceId}/rack`,
                withCredentials: true,
            })
            .then(res => {
                // sort and assign the rack rooms
                Rack.rackRooms = Object.keys(res)
                    .sort()
                    .reduce((acc, room) => {
                        acc[room] = res[room];
                        return acc;
                    }, {});
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    throw e;
                }
            });
    },

    current: {},
    load(workspaceId, id) {
        return m
            .request({
                method: "GET",
                url: `/workspace/${workspaceId}/rack/${id}`,
                withCredentials: true,
            })
            .then(res => {
                Rack.current = res;
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    throw e;
                }
            });
    },
    assignSuccess: false,
    assignDevices(workspaceId, rack) {
        const deviceAssignments = Object.keys(
            rack.slots
        ).reduce((obj, slot) => {
            const device = rack.slots[slot].assignment;
            if (device) {
                obj[device] = slot;
            }
            return obj;
        }, {});
        return m
            .request({
                method: "POST",
                url: `/workspace/${workspaceId}/rack/${rack.id}/layout`,
                data: deviceAssignments,
                withCredentials: true,
            })
            .then(res => {
                Rack.assignSuccess = true;
                setTimeout(() => {
                    Rack.assignSuccess = false;
                    m.redraw();
                }, 2600);
                Workspace.withWorkspace(workspaceId =>
                    Rack.load(workspaceId, rack.id)
                );
                return res;
            })
            .catch(e => {
                console.log(`Error in assigning devices: ${e.message}`);
            });
    },
    highlightDevice: null,
};

export default Rack;
