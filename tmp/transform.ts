import * as readline from "readline";

// 入力の型定義
interface PythonInput {
  original: {
    input: string;
  };
  processed_by: string;
  timestamp: string;
  added_fields: {
    uppercase_input: string;
    step: number;
  };
}

// 出力の型定義
interface TypeScriptOutput {
  python_output: PythonInput;
  processed_by: string;
  timestamp: string;
  added_fields: {
    step: number;
    reversed_input: string;
    input_length: number;
  };
}

async function readStdin(): Promise<string> {
  return new Promise((resolve, reject) => {
    let data = "";
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: false,
    });

    rl.on("line", (line) => {
      data += line;
    });

    rl.on("close", () => {
      resolve(data);
    });

    rl.on("error", (err) => {
      reject(err);
    });
  });
}

function transform(input: PythonInput): TypeScriptOutput {
  const originalInput = input.original?.input ?? "";

  return {
    python_output: input,
    processed_by: "typescript",
    timestamp: new Date().toISOString(),
    added_fields: {
      step: 2,
      reversed_input: [...originalInput].reverse().join(""),
      input_length: originalInput.length,
    },
  };
}

async function main(): Promise<void> {
  try {
    const rawInput = await readStdin();

    if (!rawInput.trim()) {
      throw new Error("No input received from stdin");
    }

    const parsedInput: PythonInput = JSON.parse(rawInput);

    // 入力の検証
    if (!parsedInput.original || typeof parsedInput.original.input !== "string") {
      throw new Error("Invalid input format: missing original.input");
    }
    if (parsedInput.processed_by !== "python") {
      throw new Error(`Expected processed_by to be "python", got "${parsedInput.processed_by}"`);
    }

    const output = transform(parsedInput);

    console.log(JSON.stringify(output, null, 2));
  } catch (error) {
    if (error instanceof SyntaxError) {
      console.error("Error: Invalid JSON input");
      process.exit(1);
    }
    if (error instanceof Error) {
      console.error(`Error: ${error.message}`);
      process.exit(1);
    }
    console.error("An unknown error occurred");
    process.exit(1);
  }
}

main();
