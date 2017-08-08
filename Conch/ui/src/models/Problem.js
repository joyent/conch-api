var m = require("mithril");

var Problem = {
    devices: {},
    loadDeviceProblems: function() {
        return m.request({
            method: "GET",
            url: "/problem",
            withCredentials: true
        }).then(function(res) {
            Problem.devices = res;
        }).catch(function(e) {
            console.log("Error in GET /problem: " + e.message);
        });
    },
    selected: null,
    selectDevice: function (deviceId) {
        return m.request({
            method: "GET",
            url: "/problem",
            withCredentials: true
        }).then(function(res) {
            Problem.selected = res[deviceId];
        });
    }
};


module.exports = Problem;

