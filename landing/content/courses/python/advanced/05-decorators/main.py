import functools

def log_calls(func):
    @functools.wraps(func)          # keep the original name and docstring
    def wrapper(*args):
        result = func(*args)
        print(f"log: {func.__name__} -> {result}")
        return result
    return wrapper

def require_role(role):             # a decorator with arguments
    def decorator(func):
        @functools.wraps(func)
        def wrapper(user, *args):
            if role not in user["roles"]:
                return f"denied: {user['name']} is not {role}"
            return func(user, *args)
        return wrapper
    return decorator

@log_calls                          # decorators stack: bottom one first
@require_role("admin")
def refund(user, amount):
    return f"{user['name']} refunded {amount:.2f} EUR"

ana = {"name": "Ana", "roles": ["admin", "sales"]}
luis = {"name": "Luis", "roles": ["sales"]}

print(refund(ana, 30))
print(refund(luis, 30))
print("Name kept:", refund.__name__)
