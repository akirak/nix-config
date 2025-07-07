#!/usr/bin/env deno run --allow-run --allow-read

/**
 * Claude Code Desktop Notification Forwarder
 *
 * This script reads JSON notification data from stdin and forwards it
 * to the desktop notification system using notify-desktop.
 */

interface NotificationData {
  session_id: string;
  transcript_path: string;
  message: string;
  title: string;
}

async function main() {
  try {
    // Read all JSON data from stdin until EOF
    const decoder = new TextDecoder();
    const chunks: Uint8Array[] = [];
    const buffer = new Uint8Array(4096);

    while (true) {
      const bytesRead = await Deno.stdin.read(buffer);
      if (!bytesRead) break;
      chunks.push(buffer.slice(0, bytesRead));
    }

    if (chunks.length === 0) {
      console.error("No input received from stdin");
      Deno.exit(1);
    }

    // Concatenate all chunks
    const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
    const allData = new Uint8Array(totalLength);
    let offset = 0;
    for (const chunk of chunks) {
      allData.set(chunk, offset);
      offset += chunk.length;
    }

    const jsonText = decoder.decode(allData);
    const data: NotificationData = JSON.parse(jsonText);

    // Validate required fields
    if (!data.title || !data.message) {
      console.error("Missing required fields: title and message");
      Deno.exit(1);
    }

    // Send notification using notify-desktop
    const command = new Deno.Command("notify-desktop", {
      args: [
        "--app-name",
        "Claude Code",
        "--icon",
        "terminal",
        "--urgency",
        "normal",
        data.title,
        data.message,
      ],
      stdout: "piped",
      stderr: "piped",
    });

    const { code, stdout, stderr } = await command.output();

    if (code !== 0) {
      const errorText = new TextDecoder().decode(stderr);
      console.error(`notify-desktop failed with code ${code}: ${errorText}`);
      Deno.exit(code);
    }

    console.log("Notification sent successfully");
  } catch (error) {
    if (error instanceof SyntaxError) {
      console.error("Invalid JSON input:", error.message);
    } else {
      console.error("Error:", error.message);
    }
    Deno.exit(1);
  }
}

if (import.meta.main) {
  await main();
}
