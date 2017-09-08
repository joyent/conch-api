var m = require("mithril");

function sortObject(obj) {
    return Object.keys(obj).sort().reduce(
        function(acc, i) {
            acc[i] = obj[i];
            return acc;
        }, {});
}

var Problem = {
    devices: {},
    current: null,
    loadDeviceProblems: function() {
        return m.request({
            method: "GET",
            url: "/problem",
            withCredentials: true
        }).then(function(res) {
            Problem.devices = {
                failing    : sortObject(res.failing),
                unlocated  : sortObject(res.unlocated),
                unreported : sortObject(res.unreported),
            };
        }).catch(function(e) {
            if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
              console.log("Error in GET /problem: " + e.message);
            }
        });
    },
    deviceHasProblem: function(deviceId) {
        // Search through all categories for a matching deviceId
        return Object.keys(Problem.devices).some(function(group) {
            return Problem.devices[group][deviceId];
        });
    },
};


module.exports = Problem;

