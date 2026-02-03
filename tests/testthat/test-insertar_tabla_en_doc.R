test_that("insertar_tabla_en_doc pasa el keyword a cursor_reach", {
  
  called_keyword <- NULL
  
  local_mocked_bindings(
    cursor_reach = function(doc, keyword) {
      called_keyword <<- keyword
      doc
    },
    body_end_section_portrait = function(doc) doc,
    body_end_section_landscape = function(doc) doc,
    .package = "officer"
  )
  
  local_mocked_bindings(
    body_add_flextable = function(doc, value, align) doc,
    .package = "flextable"
  )
  
  insertar_tabla_en_doc("doc", "MI SECCION", "ft")
  
  expect_identical(called_keyword, "MI SECCION")
})
