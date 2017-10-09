import m from "mithril";
import t from "i18n4v";
import moment from "moment";
import Device from "./views/Device";
import Layout from "./views/Layout";
import Login from "./views/Login";
import Problem from "./views/Problem";
import Rack from "./views/Rack";
import Status from "./views/Status";
import RelayList from "./views/Relay/List";
import RelayDetail from "./views/Relay/Detail";
import korean from "./languages/ko.js";
const languages = {
    en: require("./languages/en.js"),
    ko: korean,
    "ko-KR": korean,
};

t.selectLanguage(["en", "ko", "ko-KR"], (err, lang) => {
    moment.locale(lang ? lang.slice(0, 2) : "en");
    t.translator.add(languages[lang] ? languages[lang] : languages.en);
});

m.route(document.body, "/", {
    "/": {
        render() {
            return m(Layout.twoPane, { active: 0, title: "Status" }, m(Status));
        },
    },
    "/status": {
        render() {
            return m(Layout.twoPane, { active: 1, title: "Status" }, m(Status));
        },
    },
    "/rack": {
        render() {
            return m(
                Layout.threePane,
                { active: 1, title: "Racks" },
                m(Rack.allRacks),
                m(Rack.makeSelection)
            );
        },
    },
    "/rack/:id": {
        render({attrs}) {
            return m(
                Layout.threePane,
                { active: 2, title: "Rack" },
                m(Rack.allRacks),
                m(Rack.rackLayout, attrs)
            );
        },
    },
    "/problem": {
        render(vnode) {
            return m(
                Layout.threePane,
                { active: 1, title: "Problems" },
                m(Problem.selectProblemDevice),
                m(Problem.makeSelection)
            );
        },
    },
    "/problem/:id": {
        render({attrs}) {
            return m(
                Layout.threePane,
                { active: 2, title: "Problem" },
                m(Problem.selectProblemDevice, attrs),
                m(Problem.showDevice, attrs)
            );
        },
    },
    "/device": {
        render(vnode) {
            return m(
                Layout.threePane,
                { active: 1, title: "Device Reports" },
                m(Device.allDevices),
                m(Device.makeSelection)
            );
        },
    },
    "/device/:id": {
        render({attrs}) {
            return m(
                Layout.threePane,
                { active: 2, title: "Report" },
                m(Device.allDevices),
                m(Device.deviceReport, attrs)
            );
        },
    },
    "/relay": {
        render: vnode => {
            return m(
                Layout.threePane,
                { active: 1, title: "Relays" },
                m(RelayList),
                m(RelayDetail)
            );
        },
    },
    "/relay/:id": {
        render: ({ attrs }) => {
            return m(
                Layout.threePane,
                { active: 2, title: "Relay" },
                m(RelayList, attrs),
                m(RelayDetail, attrs)
            );
        },
    },
    "/login": Login,
});
