
import re
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# -----------------------------------
# 1. EXCEL CONFIGURATION
# -----------------------------------

EXCEL_FILE = Path(r"C:\Users\shobi\Documents\GitHub\Bookmyshow_SQL_-_PowerBI_project\data\BookMyShow_Dataset.xlsx")

# -----------------------------------
# 2. MYSQL CONFIGURATION
# -----------------------------------

MYSQL_HOST = "localhost"
MYSQL_PORT = 3306
MYSQL_USER = "root"
MYSQL_PASSWORD = "root"
DATABASE_NAME = "bookmyshow_db"


# -----------------------------------
# 3. CLEAN TABLE/COLUMN NAMES
# -----------------------------------

def clean_name(name):
    name = str(name).strip().lower()
    name = re.sub(r"[^a-zA-Z0-9_]+", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")

    if not name:
        name = "column"

    if name[0].isdigit():
        name = "col_" + name

    return name


def make_unique_names(names):
    result = []
    used = set()

    for name in names:
        base = clean_name(name)
        candidate = base
        counter = 1

        while candidate in used:
            candidate = f"{base}_{counter}"
            counter += 1

        used.add(candidate)
        result.append(candidate)

    return result


# -----------------------------------
# 4. CHECK EXCEL FILE
# -----------------------------------

if not EXCEL_FILE.exists():
    raise FileNotFoundError(f"Excel file not found: {EXCEL_FILE}")


# -----------------------------------
# 5. CONNECT TO MYSQL SERVER
# -----------------------------------

server_url = URL.create(
    drivername="mysql+pymysql",
    username=MYSQL_USER,
    password=MYSQL_PASSWORD,
    host=MYSQL_HOST,
    port=MYSQL_PORT,
    query={"charset": "utf8mb4"}
)

server_engine = create_engine(server_url)

# Create database if it does not exist
with server_engine.begin() as connection:
    connection.execute(
        text(
            f"CREATE DATABASE IF NOT EXISTS `{DATABASE_NAME}` "
            "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
        )
    )

# Connect to the selected database
database_url = server_url.set(database=DATABASE_NAME)
engine = create_engine(database_url)

print("Successfully connected to MySQL!")
print(f"Database: {DATABASE_NAME}")


# -----------------------------------
# 6. READ ALL EXCEL SHEETS
# -----------------------------------

sheets = pd.read_excel(
    EXCEL_FILE,
    sheet_name=None,
    engine="openpyxl"
)

print(f"\nTotal sheets found: {len(sheets)}")


# -----------------------------------
# 7. UPLOAD ALL SHEETS TO MYSQL
# -----------------------------------

used_tables = set()

for sheet_name, df in sheets.items():

    if df.empty:
        print(f"Skipping empty sheet: {sheet_name}")
        continue

    # Convert sheet name into table name
    table_name = clean_name(sheet_name)

    # Avoid duplicate table names
    base_name = table_name
    counter = 1

    while table_name in used_tables:
        table_name = f"{base_name}_{counter}"
        counter += 1

    used_tables.add(table_name)

    # Clean column names
    df.columns = make_unique_names(df.columns)

    # Replace infinity values with NULL
    df = df.replace([float("inf"), float("-inf")], None)

    print(f"\nUploading sheet: {sheet_name}")
    print(f"Table name: {table_name}")
    print(f"Rows: {len(df)}")
    print(f"Columns: {len(df.columns)}")

    # Upload to MySQL
    df.to_sql(
        name=table_name,
        con=engine,
        if_exists="replace",
        index=False,
        chunksize=1000
    )

    print(f"Successfully uploaded: {table_name}")


# -----------------------------------
# 8. VERIFY UPLOADED TABLES
# -----------------------------------

with engine.connect() as connection:

    result = connection.execute(
        text("SHOW TABLES")
    )

    print("\nTables available in MySQL:")

    for row in result:
        print(row[0])


# -----------------------------------
# 9. CLOSE CONNECTIONS
# -----------------------------------

engine.dispose()
server_engine.dispose()

print("\nAll Excel sheets uploaded successfully!")
