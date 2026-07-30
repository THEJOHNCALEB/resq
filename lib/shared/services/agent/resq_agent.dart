import 'package:flutter_gemma/flutter_gemma.dart';
import 'resq_tools.dart';

class TraceStep {
  TraceStep(this.tool, this.args, this.result);
  final String tool;
  final Map<String, dynamic> args;
  final String result;
}

class AgentTurn {
  AgentTurn(this.reply, this.trace);
  final String reply;
  final List<TraceStep> trace;
}

class ResQAgent {
  ResQAgent(this.chat, this.executor);
  final InferenceChat chat;
  final ResQToolExecutor executor;

  static const _maxHops = 6;

  Future<AgentTurn> ask(String userText) async {
    final trace = <TraceStep>[];
    await chat.addQuery(Message.text(text: userText, isUser: true));

    for (var hop = 0; hop < _maxHops; hop++) {
      final resp = await chat.generateChatResponse();

      final calls = switch (resp) {
        FunctionCallResponse c => [c],
        ParallelFunctionCallResponse p => p.calls,
        _ => const <FunctionCallResponse>[],
      };

      if (calls.isEmpty) {
        final reply = resp is TextResponse ? resp.token.trim() : '';
        return AgentTurn(
          reply.isEmpty
              ? "I couldn't process that — try describing the situation differently."
              : reply,
          trace,
        );
      }

      for (final call in calls) {
        final result = executor.run(call.name, call.args);
        trace.add(TraceStep(call.name, call.args, result));
        await chat.addQuery(
          Message.toolResponse(
            toolName: call.name,
            response: {'result': result},
          ),
        );
      }
    }

    return AgentTurn(
      'That took more steps than expected — please try again with a clearer description.',
      trace,
    );
  }
}
