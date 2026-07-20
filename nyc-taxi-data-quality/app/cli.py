import typer

from app.core.runner import backfill_task, list_runs, rerun_task, run_task
from app.db.init_db import init_db

app = typer.Typer()


def print_run_result(result: dict):
    typer.echo("-" * 60)
    typer.echo(f"run_id        : {result['run_id']}")
    typer.echo(f"task_name     : {result['task_name']}")
    typer.echo(f"biz_date      : {result['biz_date']}")
    typer.echo(f"row_count     : {result['row_count']}")
    typer.echo(f"passed_rules  : {result['passed_rules']}")
    typer.echo(f"failed_rules  : {result['failed_rules']}")
    typer.echo(f"status        : {result['status']}")
    typer.echo("-" * 60)


def print_runs_table(rows):
    if not rows:
        typer.echo("No run records found.")
        return

    headers = [
        "ID", "TASK", "DATE", "TYPE", "STATUS",
        "ROWS", "PASS", "FAIL", "STARTED_AT"
    ]
    widths = [5, 26, 12, 10, 10, 8, 8, 8, 20]

    def fmt(values):
        return "".join(str(v)[:w].ljust(w) for v, w in zip(values, widths))

    typer.echo(fmt(headers))
    typer.echo("-" * sum(widths))

    for row in rows:
        row_values = [
            row[0],  # id
            row[1],  # task_name
            row[2],  # biz_date
            row[3],  # run_type
            row[4],  # status
            row[5],  # row_count
            row[6],  # passed_rules
            row[7],  # failed_rules
            row[9],  # started_at
        ]
        typer.echo(fmt(row_values))


@app.command()
def init():
    init_db()
    typer.echo("Database initialized.")


@app.command()
def run(task: str, biz_date: str):
    result = run_task(task, biz_date)
    print_run_result(result)


@app.command("list-runs")
def list_runs_cmd(limit: int = 10):
    rows = list_runs(limit)
    print_runs_table(rows)


@app.command()
def rerun(run_id: int):
    result = rerun_task(run_id)
    print_run_result(result)


@app.command()
def backfill(task: str, start_date: str, end_date: str):
    results = backfill_task(task, start_date, end_date)
    for result in results:
        print_run_result(result)


if __name__ == "__main__":
    app()