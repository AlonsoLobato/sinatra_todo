$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? Deleting a todo cannot be undone!")
    if (ok) {
      this.submit();
    }
  });
});
