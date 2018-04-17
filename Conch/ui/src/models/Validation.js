import m from "mithril";

const Validation = {
    list: [],
    idToName: {},
    load() {
        return m
            .request({
                method: "get",
                url: "/validation",
            })
            .then(validations => {
                Validation.list = validations;
                Validation.idToName = validations.reduce(
                    (acc, { id, name }) => {
                        acc[id] = name;
                        return acc;
                    },
                    {}
                );
            });
    },
};

export default Validation;
