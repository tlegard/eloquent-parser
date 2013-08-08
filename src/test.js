if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  console.log(take(2, [1, 2, 3, 4, 5]));
}).call(this);
