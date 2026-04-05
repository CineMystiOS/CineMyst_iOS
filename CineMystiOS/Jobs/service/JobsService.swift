import Foundation
import Supabase

class JobsService {
    static let shared = JobsService()
    
    // Using global 'supabase' client from Supabase.swift
    
    private init() {}
    
    func fetchActiveJobs() async throws -> [Job] {
        let response: [Job] = try await supabase
            .from("jobs")
            .select()
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    func fetchJobs() async throws -> [Job] {
        let response: [Job] = try await supabase
            .from("jobs")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    func createJob(_ job: Job) async throws -> Job {
        do {
            let response: [Job] = try await supabase
                .from("jobs")
                .insert(job)
                .select()
                .execute()
                .value
            
            guard let savedJob = response.first else {
                throw NSError(domain: "JobsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Job was created but could not be retrieved"])
            }
            
            return savedJob
        } catch {
            print("❌ Error in createJob: \(error)")
            throw error
        }
    }

    func createTask(_ task: JobTask) async throws -> JobTask {
        do {
            let response: [JobTask] = try await supabase
                .from("tasks")
                .insert(task)
                .select()
                .execute()
                .value
            return response.first!
        } catch {
            print("❌ Error in createTask: \(error)")
            throw error
        }
    }

    func fetchTaskForJob(jobId: UUID) async throws -> JobTask? {
        do {
            let tasks: [JobTask] = try await supabase
                .from("tasks")
                .select()
                .eq("job_id", value: jobId.uuidString)
                .execute()
                .value
            
            // Check if it's a real task (has title or description)
            return tasks.first { $0.taskTitle != nil || $0.taskDescription != nil }
        } catch {
            print("❌ Error fetching task for job: \(error)")
            return nil
        }
    }
    
    func applyToJob(jobId: UUID, portfolioUrl: String) async throws -> Application {
        guard let actorId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "JobsService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User must be logged in to apply"])
        }
        
        let application = Application(
            id: UUID(),
            jobId: jobId,
            actorId: actorId,
            status: .portfolioSubmitted,
            portfolioUrl: portfolioUrl,
            portfolioSubmittedAt: Date(),
            appliedAt: Date(),
            updatedAt: Date()
        )
        
        let response: Application = try await supabase
            .from("applications")
            .insert(application)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }

    // MARK: - Restored Missing Methods
    
    func fetchJobsByDirector(directorId: UUID, status: Job.JobStatus?) async throws -> [Job] {
        var query = supabase
            .from("jobs")
            .select()
            .eq("director_id", value: directorId.uuidString)
        
        if let status = status {
            query = query.eq("status", value: status.rawValue)
        }
        
        let response: [Job] = try await query
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    func fetchJobsByIds(jobIds: [UUID]) async throws -> [Job] {
        guard !jobIds.isEmpty else { return [] }
        let idStrings = jobIds.map { $0.uuidString }
        let response: [Job] = try await supabase
            .from("jobs")
            .select()
            .in("id", values: idStrings)
            .execute()
            .value
        return response
    }
    
    func toggleBookmark(jobId: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }
        
        let existing: [Bookmark] = try await supabase
            .from("bookmarks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("job_id", value: jobId.uuidString)
            .execute()
            .value
            
        if existing.isEmpty {
            try await supabase
                .from("bookmarks")
                .insert(["user_id": userId.uuidString, "job_id": jobId.uuidString])
                .execute()
        } else {
            try await supabase
                .from("bookmarks")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("job_id", value: jobId.uuidString)
                .execute()
        }
    }

    // MARK: - Storage Support
    
    func uploadFile(fileData: Data, fileName: String, bucket: String, folder: String) async throws -> String {
        let path = "\(folder)/\(fileName)"
        _ = try await supabase.storage
            .from(bucket)
            .upload(
                path: path,
                file: fileData,
                options: FileOptions(contentType: nil, upsert: true)
            )
        
        let url = try supabase.storage
            .from(bucket)
            .getPublicURL(path: path)
            
        return url.absoluteString
    }
}

// Simple Bookmark model for the toggle logic
struct Bookmark: Codable {
    let user_id: String
    let job_id: String
}
