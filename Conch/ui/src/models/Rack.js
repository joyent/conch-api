import m from "mithril";

const Rack = {
    // Associative array of room names to list of racks
    rackRooms: {},
    loadRooms() {
        return m
            .request({
                method: "GET",
                url: "/rack",
                withCredentials: true,
            })
            .then(res => {
                // sort and assign the rack rooms
                Rack.rackRooms = Object.keys(res.racks)
                    .sort()
                    .reduce((acc, room) => {
                        acc[room] = res.racks[room];
                        return acc;
                    }, {});
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    console.log(`Error in GET /rack: ${e.message}`);
                }
            });
    },

    current: {},
    load(id) {
        return m
            .request({
                method: "GET",
                url: `/rack/${id}`,
                withCredentials: true,
            })
            .then(res => {
                Rack.current = res;
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    console.log(`Error in GET /rack/${id}: ${e.message}`);
                }
            });
    },
    assignSuccess: false,
    assignDevices(rack) {
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
                url: `/rack/${rack.id}/layout`,
                data: deviceAssignments,
                withCredentials: true,
            })
            .then(res => {
                Rack.assignSuccess = true;
                setTimeout(() => {
                    Rack.assignSuccess = false;
                    m.redraw();
                }, 2600);
                Rack.load(rack.id);
                return res;
            })
            .catch(e => {
                console.log(`Error in assigning devices${e.message}`);
            });
    },
    highlightDevice: null,
};

export default Rack;
