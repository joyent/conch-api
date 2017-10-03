const m = require("mithril");

const Icons = require("./Icons");
const Device = require("../../models/Device");

// Given a Device, renders icons in a <div> showing the current status.
module.exports = {
    view: ({ attrs }) => {
        const device = attrs.device;
        if (device) {
            let healthIcon;
            if (device.health === "PASS") {
                healthIcon = Icons.passValidation;
            } else if (device.health === "FAIL") {
                healthIcon = Icons.failValidation;
            } else {
                healthIcon = Icons.noReport;
            }

            return m(
                ".device-status",
                healthIcon,
                Device.isActive(device) ? Icons.deviceReporting : null
            );
        }
        return m(".device-status");
    },
};
