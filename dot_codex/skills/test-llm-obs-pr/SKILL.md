---
name: test-llm-obs-pr
description: Test a change to the llm-obs Rapid service by running it locally and doing real cURL commands.
---

You are testing the most recent set of changes made to the llm-obs Rapid service.

# Make a list of all API requests based on the current changes

Run:

```
git diff main
```

Use that diff to determine all API requests that should be tested. Prompt the user to confirm that the proposed tests look good before running them. Format the proposed tests as a table with the endpoint in one column, the test name in another column, and a description in the final column.

# Run the cURL commands and confirm the behavior

Use `curl` to test the API. Your `curl` commands should include a `dd-auth-jwt`, which you can get using `ddauth`. The commands should look like this:

```
JWT=$(ddauth obo -o 2 | grep dd-auth-jwt | cut -d' ' -f2)
curl -H "dd-auth-jwt: $JWT" http://localhost:8080/THE-ENDPOINT-WE-ARE-TESTING
```

Use `localhost:8080` as the domain.

# Summarize all tests

Summarize the results of your testing.
