var m = require("mithril");

var Device = {
    devices: [],
    loadDevices: function() {
        return m.request({
            method: "GET",
            url: "/device",
            withCredentials: true
        }).then(function(res) {
            Device.devices = res.sort();
        }).catch(function(e) {
            if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
                console.log("Error in GET /device: " + e.message);
            }
        });
    },
    deviceReport: {},
    loadDeviceReport: function(deviceId) {
        return m.request({
            method: "GET",
            url: "/device/" + deviceId,
            withCredentials: true
        }).then(function(res) {
            Device.deviceReport = res;
        }).catch(function(e) {
            if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
                console.log("Error in GET /device: " + e.message);
            }
        });
    }

};

module.exports = Device;
