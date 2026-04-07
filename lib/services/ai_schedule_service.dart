import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/task_model.dart';
import '../models/schedule_analysis.dart';

class AiScheduleService extends ChangeNotifier {
    ScheduleAnalysis? _currentAnalysis;
    bool _isLoading = false;
    String? _errorMessage;

    final String _apiKey = '';

    ScheduleAnalysis? get currentAnalysis => _currentAnalysis;
    bool get isLoading => _isLoading;
    String? get errorMessage => _errorMessage;

    Future<void> analyzeSchedule(List<TaskModel> tasks) async {
        if (_apiKey.isEmpty || tasks.isEmpty) return;
        _isLoading = true;
        _errorMessage = null;
        notifyListeners();

        try {
            final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey:_apiKey);
            final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
            final prompt = '''
            You are expert student scheduling assistant. The user has provided the following tasks for their day in JSON format: $tasksJson

            Your job is to analyze these tasks, identify any overlaps or conflicts in their start and end times,
            and suggest a better balanced schedule. Consider their urgency, importance and required energy level.

            Provide exactly 4 sections of markdown text:

            1. ### Detected conflicts
            List my Scheduling conflicts
            2. ### Ranked Tasks
            Rank which tasks need attention first based on urgency, importance and required energy. Provide a brief reason each.
            3. ### Recommended Schedule
            Provide a revised daily timeline view adjusting the task time to resolve conflicts and balanced the student's workload, study time and rest.
            4. ### Explanation
            Explain why this recommendation was made in simple language that a student would easily understand.
                
            Ensure the markdown is well formatted and easy to read. Do not include extra text outside of these headers.
            ''';

            final content = [Content.text(prompt)];
            final response = await model.generateContent(content);

            //final text = response.text ?? '';
            //final analysis = _parseResponse(text);
            //_currentAnalysis = analysis;

            _currentAnalysis = _parseResponse(response.text ?? '');

        } catch (e){
            _errorMessage = "Failed to analyze schedule: \$e";
        }   finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    ScheduleAnalysis _parseResponse(String fullText) {
        String conflicts = "", 
            rankedTasks = "", 
            recommendedSchedule = "",
            explanation = "";

        final sections = fullText.split('###');
        for (var section in sections) {
            if (section.startsWith('Detected Conflicts'))
                conflicts = section.replaceFirst('Detected Conflicts', '').trim();

                else if (section.startsWith('Ranked tasks'))
                rankedTasks = section.replaceFirst('Ranked tasks', '').trim();

                else if (section.startsWith('Recommended Schedule'))
                recommendedSchedule = section.replaceFirst('Recommended Schedule', '').trim();

                else if (section.startsWith('Explanation'))
                explanation = section.replaceFirst('Explanation', '').trim();
        }

        return ScheduleAnalysis (
            conflicts:conflicts,
            explanation:explanation,
            rankedTasks:rankedTasks,
            recommendedSchedule:recommendedSchedule,
        );

    }
}