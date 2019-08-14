var selectAge = document.getElementById("segmentselect");
var contents;

for (let i = 2; i <= 100; i++) {
  contents += "<option>" + i + "</option>";
}

selectAge.innerHTML = contents;
