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
    },

    rackLocation : null,
    loadRackLocation : function(deviceId) {
        return m.request({
            method: "GET",
            url: "/device/" + deviceId + "/location",
            withCredentials: true,
            extract: function(xhr) {
                return { status: xhr.status, body: JSON.parse(xhr.response) };
            }
        }).then(function(res) {
            Device.rackLocation = res.body;
        }).catch(function(e) {
            if (e.status === 401) {
                m.route.set("/login");
            }
            else if (e.status === 409 || e.status === 400) {
                Device.rackLocation = null;
            }
            else {
                console.log("Error in GET /device/" + deviceId + "/location: " + e.message);
            }
        });
    },

    logs : [],
    loadDeviceLogs : function(deviceId, limit) {
        return m.request({
            method: "GET",
            url: "/device/" + deviceId + "/log",
            data : { limit : limit },
            withCredentials: true,
        }).then(function(res) {
            Device.logs = res;
        }).catch(function(e) {
            console.log("Error in GET /device/" + deviceId + "/log: " + e.message);
        });
    }

};

module.exports = Device;
