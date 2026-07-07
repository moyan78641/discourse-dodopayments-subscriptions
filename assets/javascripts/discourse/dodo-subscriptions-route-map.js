/* eslint-disable ember/routes-segments-snake-case */
export default function () {
  this.route("dodo-subscribe", { path: "/subscribe" }, function () {
    this.route("show", { path: "/:product-id" });
    this.route("success");
  });
}
