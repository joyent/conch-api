var m = require("mithril");
var Device = require("../models/Device");

var allDevices = {
    oninit: Device.loadDevices,
    view: function(vnode) {
        return [
            m(".selection-list.pure-u-1-6", Device.devices.map(
                function(deviceId) {
                    return m("a.selection-list-item",
                        {
                            href: "/device/" + deviceId,
                            oncreate: m.route.link
                        },
                        deviceId
                    );
                })
        ),
        vnode.children.length > 0
            ? vnode.children
            : m(".make-selection.pure-u-3-4", "Select a device in the sidebar")
        ];
    }
};

var deviceReport = {
    view: function(vnode) {
        return m(".pure-u-3-4", "Device Report");
    }
};


module.exports = {
    allDevices   : allDevices,
    deviceReport : deviceReport
};
