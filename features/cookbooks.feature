# Language: en

Feature: cookbooks import
  To create sets of cookbook
  As a getchef user
  I want to be store to redis all cookbooks

  Background: Redis is available
    Given I have connect to redis with namespace test

  Scenario: Update staging cookbook sets
    Given Current sets is empty
    When Retrieve getchef cookbooks from remote
    Then Update staging sets on Redis
    But Raise exception if remote data is empty

  Scenario: Initialize
    Given Current sets is empty
    When Retrieve getchef cookbooks from remote
    And Update staging sets on Redis
    Then current sets is filled by staging sets

  Scenario: Update current cookbook sets
    Given staging sets is exist
    Then update current sets from staging
    But Raise exception if staging data is empty

  Scenario: Pick up new cookbooks
    Given I have current and staging sets on Redis
    And Some new cookbooks are available
    Then I can pick up new cookbooks

  Scenario: Find out gone cookbooks
    Given I have current and staging sets on Redis
    And Some cookbooks are gone
    Then I can find out gone cookbooks

