import asyncio

# Three warehouses answer a stock query; each one takes a different time
DELAY = {"Madrid": 0.03, "Bilbao": 0.01, "Sevilla": 0.02}
STOCK = {"Madrid": 12, "Bilbao": 0, "Sevilla": 7}

async def check_stock(city, product):
    print(f"asking {city} about {product}...")
    await asyncio.sleep(DELAY[city])         # waits without blocking the rest
    print(f"  {city} answered")
    return city, STOCK[city]

async def worker(name, jobs):
    for job in jobs:
        print(f"{name}: {job}")
        await asyncio.sleep(0)               # hand control back to the loop

async def main():
    # gather runs them at the same time and keeps the order of the results
    results = await asyncio.gather(*(check_stock(c, "chair") for c in DELAY))
    print("Results:", results)

    # Two coroutines taking turns: each await is a switch point
    await asyncio.gather(worker("packer", ["box #1", "box #2"]),
                         worker("printer", ["label #1", "label #2"]))

    try:                                     # give up if it takes too long
        await asyncio.wait_for(asyncio.sleep(1), timeout=0.05)
    except TimeoutError:
        print("Slow supplier: timed out")

asyncio.run(main())
