/* eslint-disable ember/routes-segments-snake-case */
export default {
  resource: "admin.adminPlugins",
  path: "/plugins",

  map() {
    this.route("discourse-dodo-subscriptions", function () {
      this.route("products");
    });
  },
};
