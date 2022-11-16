(namespace_definition name: (identifier) @name) @type
(namespace_definition !name) @type
(function_declarator declarator: (identifier) @name (#not-match? @name "^TEST.*")) @type
(function_declarator 
  declarator: (identifier) @test_name (#match? @test_name "^TEST.*")
  parameters: (parameter_list
                (parameter_declaration type: (type_identifier))
                (parameter_declaration type: (type_identifier) @name)
              )
) @type
(function_declarator declarator: (qualified_identifier) @name) @type
(enum_specifier name: (type_identifier) @name) @type
(class_specifier name: (type_identifier) @name) @type

