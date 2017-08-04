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
            Rack.rackRooms = res.racks;
        }).catch(function(e) {
            console.log("Error in GET /rack: " + e.message);
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
            console.log("Error in GET /rack/" + id + ": " + e.message);
        });
    },
    assignDevices: function(rack) {
        var deviceAssignments =
            Object.keys(rack.slots).reduce(function(obj, slot) {
                var device = rack.slots[slot].occupant;
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
            console.log(res);
        }).catch(function(e) {
            console.log("Error in assigning devices" + e.message);
        });
    }
}

module.exports = Rack;
