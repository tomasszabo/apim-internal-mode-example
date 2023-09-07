#r "Newtonsoft.Json"

using System.Collections.Generic;
using System.Linq;
using System.Net;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Primitives;

public static IActionResult Run(HttpRequest req, ILogger log)
{
    log.LogInformation("GetUsers function processed a request.");

    string name = req.Query["name"];

    List<User> testUsers = new List<User>
      {
        new User { Name = "Alice", Email = "alice@example.com" },
        new User { Name = "Bob", Email = "bob@example.com" },
        new User { Name = "Charlie", Email = "charlie@example.com" },
        new User { Name = "David", Email = "david@example.com" },
        new User { Name = "Eve", Email = "eve@example.com" }
      };

    var response = string.IsNullOrEmpty(name)
        ? testUsers
        : testUsers.Where(u => u.Name.ToLower().IndexOf(name) > -1);

    return new JsonResult(response);
}

public class User
{
    public string Name { get; set; }
    public string Email { get; set; }
}