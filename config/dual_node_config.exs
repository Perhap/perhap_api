node 1

[name: "bin_audit_get", schedule: "0 1 * * *", task: {Service.Cron, :bin_audit_event, []}],
[name: "apa_get", schedule: "0 */2 * * *", task: {Service.Cron, :bin_audit_event, []}],
[name: "actuals_get", schedule: "0 0,8,16 * * *", task: {Service.Cron, :actuals_event, []}],


node 2

[name: "bin_audit_get", schedule: "0 13 * * *", task: {Service.Cron, :bin_audit_event, []}],
[name: "apa_get", schedule: "0 1,3,5,7,9,11,13,15,17,19,21,23 * * *", task: {Service.Cron, :bin_audit_event, []}],
[name: "actuals_get", schedule: "0 4,12,20 * * *", task: {Service.Cron, :actuals_event, []}],
