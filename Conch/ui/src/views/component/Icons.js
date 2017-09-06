var m = require('mithril');
var t = require("i18n4v");

module.exports = {
    passValidation :
        m("i.material-icons", { title : t("Device passes validation") }, "check"),

    failValidation :
        m("i.material-icons", { title : t("Device fails validation") }, "error_outline"),

    deviceReporting :
        m("i.material-icons", { title : t("Device reporting to Conch") }, "cloud_upload"),

};
