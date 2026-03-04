---
name: test-llm-obs
description: Test a change to the llm-obs Rapid service by running it locally and doing real cURL commands.
---

You are going to be testing the most reset set of changes that have been don to the llm-obs Rapid service.

# Make a list of all the API requests based on the current changes.

Run

```
git diff main
```

to get an overview of the changes that have been made. Form that determine all
of the API requests that should be tested. Prompt me to confirm that they look good.
Please format the test you will do in a table with the endpoint in one column,
the name of the test in another column, and a final column with a description
of the test.

# Run the cURL commands and confirm the behavior.

Use `curl` to test the API. Your `curl` commands should have a `dd-auth-jwt` which
you can get using `ddauth`. The commands you run should look like the following.

```
JWT=$(ddauth obo -o 2 | grep dd-auth-jwt | cut -d' ' -f2)
curl -H "dd-auth-jwt: $JWT" http//localhost:8080/THE-ENDPOINT-WE-ARE-TESTING
```

Use `localhost:8080` as the domain.

# Give me an summary of all the test

Summarize the results of your testing.
