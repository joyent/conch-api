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
    }

};

module.exports = Device;
