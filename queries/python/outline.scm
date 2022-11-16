(function_definition
  name: (identifier) @name) @type

(class_definition
  name: (identifier) @name) @type

(module (expression_statement ((assignment left: (identifier) @name) @type)))

;; (class_definition
;;   body: (block (expression_statement ((assignment left: (identifier) @name) @type))))
