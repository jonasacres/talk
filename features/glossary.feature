Feature: @glossary
  Scenario Outline: Define an @glossary with an explicit @description
    Given I define a glossary named <name> with description <description>
    When I get the result hash
    Then there should be a glossary named <name>
    And the glossary named <name> should have description <description>

    Examples:
    | name | description |
    | AGlossary | A test glossary |
    | AnotherGlossary | More testing please |

  Scenario Outline: Define an @glossary with an implicit description
    Given I define a glossary named <name> with implicit description <description>
    When I get the result hash
    Then there should be a glossary named <name>
    And the glossary named <name> should have description <description>

    Examples:
    | name | description |
    | AGlossary | A test glossary |
    | AnotherGlossary | More testing please |

  Scenario: Define an @glossary with no description
    Given I define a glossary named SomeGlossary
    But I don't give it a description
    When I get the result hash
    Then there should be a parse error

  Scenario: Define an @glossary with no name
    Given I define a glossary
    But I don't give it a name
    When I get the result hash
    Then there should be a parse error
    