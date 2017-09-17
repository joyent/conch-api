var m = require("mithril");
var moment = require('moment');

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

    current : null,
    loadDevice: function(deviceId) {
        return m.request({
            method: "GET",
            url: "/device/" + deviceId,
            withCredentials: true
        }).then(function(res) {
            Device.current = res;
        }).catch(function(e) {
            if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
                console.log("Error in GET /device: " + e.message);
            }
        });
    },

    updatingFirmware : false,
    loadFirmwareStatus: function(deviceId) {
        return m.request({
            method: "GET",
            url: `/device/${deviceId}/settings/firmware`,
            withCredentials: true
        }).then(function(res) {
            Device.updatingFirmware = res.firmware === 'updating';
        }).catch(function(e) {
            if (e.error === "not found") {
                Device.updatingFirmware = false;
            }
            else if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
                console.log("Error in GET /device: " + e.message);
            }
        });
    },

    rackLocation : null,
    getDeviceLocation : deviceId => {
        return m.request({
            method: "GET",
            url: "/device/" + deviceId + "/location",
            withCredentials: true,
            extract: function(xhr) {
                return { status: xhr.status, body: JSON.parse(xhr.response) };
            }
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
        }).then(res => res.body);
    },
    loadRackLocation : function(deviceId) {
        return Device.getDeviceLocation(deviceId)
            .then(res => Device.rackLocation = res );
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
    },

    // A device is active if it was last seen in the last 5 minutes
    isActive : function(device) {
        if (device.last_seen) {
            var lastSeen = moment(device.last_seen);
            var fiveMinutesAgo = moment().subtract(5, 'm');
            return (fiveMinutesAgo < lastSeen);
        }
        return false;
    }
};

module.exports = Device;
