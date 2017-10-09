import m from "mithril";

const Auth = {
    username: "",
    password: "",

    setUsername(value) {
        Auth.username = value;
    },
    setPassword(value) {
        Auth.password = value;
    },
    login() {
        return m
            .request({
                method: "POST",
                url: "/login",
                data: { user: Auth.username, password: Auth.password },
            })
            .then(data => {
                m.route.set("/rack");
            })
            .catch(e => {
                console.log("An error fired: ");
                console.log(e);
            });
    },
    logout() {
        return m.request({ method: "POST", url: "/logout" });
    },
};

export default Auth;
