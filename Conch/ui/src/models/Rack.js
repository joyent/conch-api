var m = require("mithril");

var Rack = {
    // Associative array of room names to list of racks
    rackRooms: {},
    loadRooms: function() {
        return m.request({
            method: "GET",
            url: "/rack",
            withCredentials: true
        }).then(function(res) {
            // sort and assign the rack rooms
            Rack.rackRooms =
                Object.keys(res.racks).sort().reduce(
                    function(acc, room) {
                        acc[room] = res.racks[room];
                        return acc;
                    }, {});
        }).catch(function(e) {
            if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
                console.log("Error in GET /rack: " + e.message);
            }
        });
    },

    current: {},
    load: function(id) {
        return m.request({
            method: "GET",
            url: "/rack/" + id,
            withCredentials: true
        }).then(function(res) {
            Rack.current = res.rack;
        }).catch(function(e) {
            if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
                console.log("Error in GET /rack/" + id + ": " + e.message);
            }
        });
    },
    assignSuccess: false,
    assignDevices: function(rack) {
        var deviceAssignments =
            Object.keys(rack.slots).reduce(function(obj, slot) {
                var device = rack.slots[slot].assignment;
                if (device) {
                    obj[device] = slot;
                }
                return obj;
            }, {});
        return m.request({
            method: "POST",
            url: "/rack/" + rack.id + "/layout",
            data: deviceAssignments,
            withCredentials: true
        }).then(function(res) {
            Rack.assignSuccess = true;
            setTimeout(
                function(){ Rack.assignSuccess = false; m.redraw();},
                2600
            );
            Rack.load(rack.id);
            return res;
        }).catch(function(e) {
            console.log("Error in assigning devices" + e.message);
        });
    },
    highlightDevice: null
};

module.exports = Rack;
