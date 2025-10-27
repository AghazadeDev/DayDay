//
//  AnalyticsView.swift
//  DayDay
//
//  Created by Alikhan Aghazada on 29.09.25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    let isLoading: Bool
    let error: String?
    let categories: [Category]
    let notesByCategory: [String: [NoteWithMeta]]
    let onRetry: () -> Void
    
    private var categoryBars: [CategoryCount] {
        categories.map { cat in
            CategoryCount(category: cat.name, count: notesByCategory[cat.name]?.count ?? 0)
        }
        .sorted { $0.count > $1.count }
    }
    
    private var daySeries: [DayCount] {
        // Build last 30 days window
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<30).compactMap { offset -> Date? in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.sorted()
        
        // Flatten all notes
        let allNotes = notesByCategory.values.flatMap { $0 }
        
        let grouped: [Date: Int] = days.reduce(into: [:]) { acc, day in
            let next = calendar.date(byAdding: .day, value: 1, to: day)!
            let count = allNotes.filter { n in
                let created = n.createdAt
                return (created >= day && created < next)
            }.count
            acc[day] = count
        }
        
        return days.map { DayCount(day: $0, count: grouped[$0] ?? 0) }
    }
    
    private var averageLength: Int {
        let allNotes = notesByCategory.values.flatMap { $0 }
        guard !allNotes.isEmpty else { return 0 }
        let total = allNotes.reduce(0) { $0 + max($1.content.count, $1.title.count) }
        return total / allNotes.count
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Загрузка аналитики...")
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("Не удалось загрузить данные")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Повторить") { onRetry() }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Summary
                        SummaryCard(totalNotes: notesByCategory.values.reduce(0) { $0 + $1.count },
                                    avgLength: averageLength)
                        
                        // Notes per category
                        if !categoryBars.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Заметки по категориям")
                                    .font(.headline)
                                Chart(categoryBars.prefix(8)) { item in
                                    BarMark(
                                        x: .value("Количество", item.count),
                                        y: .value("Категория", item.category)
                                    )
                                    .foregroundStyle(.purple.gradient)
                                }
                                .frame(height: max(180, CGFloat(min(categoryBars.count, 8)) * 28 + 40))
                            }
                            .padding(.horizontal)
                        }
                        
                        // Activity by day
                        if !daySeries.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Активность по дням (30 дней)")
                                    .font(.headline)
                                Chart(daySeries) { item in
                                    LineMark(
                                        x: .value("День", item.day, unit: .day),
                                        y: .value("Заметки", item.count)
                                    )
                                    .foregroundStyle(.purple)
                                    AreaMark(
                                        x: .value("День", item.day, unit: .day),
                                        y: .value("Заметки", item.count)
                                    )
                                    .foregroundStyle(.purple.opacity(0.2))
                                }
                                .frame(height: 220)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Top categories list
                        if !categoryBars.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Топ категорий")
                                    .font(.headline)
                                ForEach(categoryBars.prefix(5)) { item in
                                    HStack {
                                        Text(item.category)
                                        Spacer()
                                        Text("\(item.count)")
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                    Divider()
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 16)
                    }
                    .padding(.top, 16)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SummaryCard: View {
    let totalNotes: Int
    let avgLength: Int
    
    var body: some View {
        HStack(spacing: 12) {
            MetricView(title: "Всего заметок", value: "\(totalNotes)", color: .purple)
            MetricView(title: "Средняя длина", value: "\(avgLength)", color: .blue)
        }
        .padding(.horizontal)
    }
}

private struct MetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2).bold()
            Rectangle()
                .fill(color.gradient)
                .frame(height: 4)
                .clipShape(Capsule())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct CategoryCount: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

struct DayCount: Identifiable {
    let id = UUID()
    let day: Date
    let count: Int
}

