Feature: @enumeration -> @constant
  
  Scenario Outline: Define a constant
    Given I have defined a valid enumeration named <enumeration>
    And I define a constant named <constant> with value <value> and description <description>
    When I get the result hash
    Then the enumeration <enumeration> should contain a constant named <constant>
    And the constant <constant> of enumeration <enumeration> should have value <value>
    And the constant <constant> of enumeration <enumeration> should have description <description>

    Examples:
    | enumeration        | constant        | value | description         |
    | AnEnumeration      | AConstant       | 1     | A description       |
    | AnotherEnumeration | AnotherConstant | 4     | Another description |

  Scenario Outline: Define multiple constants
    Given I have defined a valid enumeration named <enumeration>
    And I define a constant named <constant_1> with value <value_1> and description <description_1>
    And I define a constant named <constant_2> with value <value_2> and description <description_2>
    When I get the result hash
    Then the enumeration <enumeration> should contain a constant named <constant_1>
    And the constant <constant_1> of enumeration <enumeration> should have value <value_1>
    And the constant <constant_1> of enumeration <enumeration> should have description <description_1>
    And the enumeration <enumeration> should contain a constant named <constant_2>
    And the constant <constant_2> of enumeration <enumeration> should have value <value_2>
    And the constant <constant_2> of enumeration <enumeration> should have description <description_2>

    Examples:
    | enumeration        | constant_1  | value_1 | description_1 | constant_2  | value_2 | description_2       |
    | AnEnumeration      | Constant1   | 1       | A Description | Constant2   | 2       | Another Description |
    | AnotherEnumeration | ConstantA   | 2       | A Description | ConstantB   | 1       | Another Description |
    | AThirdEnumeration  | ConstantOne | 2       | Numeral two   | ConstantTwo | 2       | Ordinal two         |

  Scenario: Define constants with implied values
    Given I have defined a valid enumeration named AnEnumeration
    And I define a valid constant named Constant0
    And I define a valid constant named Constant1
    And I define a valid constant named Constant2
    When I get the result hash
    Then the constant Constant0 of enumeration AnEnumeration should have value 0
    Then the constant Constant1 of enumeration AnEnumeration should have value 1
    Then the constant Constant2 of enumeration AnEnumeration should have value 2


  Scenario Outline: Define constants with mixed explicit and implied values
    Given I have defined a valid enumeration named AnEnumeration
    And I define a valid constant named Constant1 with value <value1>
    And I define a valid constant named Constant2
    And I define a valid constant named Constant3
    And I define a valid constant named Constant4 with value <value4>
    And I define a valid constant named Constant5
    When I get the result hash
    Then the constant Constant1 of enumeration AnEnumeration should have value <value1>
    And the constant Constant2 of enumeration AnEnumeration should have value <expected2>
    And the constant Constant3 of enumeration AnEnumeration should have value <expected3>
    And the constant Constant4 of enumeration AnEnumeration should have value <value4>
    And the constant Constant5 of enumeration AnEnumeration should have value <expected5>

    Examples:
    | value1 | expected2 | expected3 | value4 | expected5 |
    | 1      | 2         | 3         | 4      | 5         |
    | 0      | 1         | 2         | 10     | 11        |

  Scenario Outline: Define a constant with an interpreted expression
    Given I have defined a valid enumeration named AnEnumeration
    And I define a valid constant named Expressive with value <expression>
    When I get the result hash
    Then the constant Expressive should have value <output>

    Examples:
    | expression  | output |
    | 0           | 0      |
    | Math.cos(0) | 1      |
    | 0x10        | 16     |
    | 1 << 8      | 256    |
    