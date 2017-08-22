var m = require("mithril");

var Device = {
    deviceIds: [],
    loadDeviceIds: function() {
        return m.request({
            method: "GET",
            url: "/device",
            withCredentials: true
        }).then(function(res) {
            Device.deviceIds = res.sort();
        }).catch(function(e) {
            if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
                console.log("Error in GET /device: " + e.message);
            }
        });
    },

    devices : [],
    loadDevices : function() {
        return m.request({
            method: "GET",
            url: "/device",
            data : { full : 1 },
            withCredentials: true
        }).then(function(res) {
            Device.devices = res.sort(function(a, b) {
                if (a.id < b.id) {
                    return -1;
                }
                if (a.id > b.id) {
                    return 1;
                }
                return 0;
            });
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
            Device.deviceReport.id = deviceId;
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
