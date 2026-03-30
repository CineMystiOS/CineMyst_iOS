//
//  JobsService.swift
//  CineMystApp
//
//  Created by user@55 on 17/01/26.
//
import Foundation
import Supabase

class JobsService {
    static let shared = JobsService()
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://kyhyunyobgouumgwcigk.supabase.co")!,
        supabaseKey: "sb_publishable_oJe1X9aiPdKm6wqR1zvFhA_aIiej9-d"
    )
    
    // Add to JobsService class

    // MARK: - Bookmarks

    func toggleBookmark(jobId: UUID) async throws -> Bool {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        // Check if already bookmarked
        let existing: [JobBookmark] = try await supabase
            .from("job_bookmarks")
            .select()
            .eq("job_id", value: jobId.uuidString)
            .eq("actor_id", value: userId.uuidString)
            .execute()
            .value
        
        if existing.isEmpty {
            // Add bookmark
            let bookmark = JobBookmark(
                id: UUID(),
                jobId: jobId,
                actorId: userId,
                bookmarkedAt: Date()
            )
            
            let _: JobBookmark = try await supabase
                .from("job_bookmarks")
                .insert(bookmark)
                .single()
                .execute()
                .value
            
            return true // Now bookmarked
        } else {
            // Remove bookmark
            try await supabase
                .from("job_bookmarks")
                .delete()
                .eq("job_id", value: jobId.uuidString)
                .eq("actor_id", value: userId.uuidString)
                .execute()
            
            return false // No longer bookmarked
        }
    }

    func isJobBookmarked(jobId: UUID) async throws -> Bool {
        guard let userId = supabase.auth.currentUser?.id else {
            return false
        }
        
        let bookmarks: [JobBookmark] = try await supabase
            .from("job_bookmarks")
            .select()
            .eq("job_id", value: jobId.uuidString)
            .eq("actor_id", value: userId.uuidString)
            .execute()
            .value
        
        return !bookmarks.isEmpty
    }

    func fetchBookmarkedJobs() async throws -> [Job] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        // Fetch bookmarked job IDs
        let bookmarks: [JobBookmark] = try await supabase
            .from("job_bookmarks")
            .select()
            .eq("actor_id", value: userId.uuidString)
            .execute()
            .value
        
        let jobIds = bookmarks.map { $0.jobId.uuidString }
        
        // Fetch the actual jobs
        let jobs: [Job] = try await supabase
            .from("jobs")
            .select()
            .in("id", values: jobIds)
            .execute()
            .value
        
        return jobs
    }
    
    func fetchJobsByIds(jobIds: [UUID]) async throws -> [Job] {
        guard !jobIds.isEmpty else {
            return []
        }
        
        let jobIdStrings = jobIds.map { $0.uuidString }
        
        let jobs: [Job] = try await supabase
            .from("jobs")
            .select()
            .in("id", values: jobIdStrings)
            .execute()
            .value
        
        return jobs
    }
    
    // MARK: - Jobs
    
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
    
    func fetchJobsByDirector(directorId: UUID, status: Job.JobStatus? = nil) async throws -> [Job] {
        print("🔎 JobsService: Fetching jobs for director \(directorId.uuidString.prefix(8))")
        print("   Filtering by status: \(status?.rawValue ?? "none (all statuses)")")
        
        var query = supabase
            .from("jobs")
            .select()
            .eq("director_id", value: directorId.uuidString)
        
        if let status = status {
            query = query.eq("status", value: status.rawValue)
            print("   Query filter: status == '\(status.rawValue)'")
        }
        
        let response: [Job] = try await query
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("📦 JobsService: Received \(response.count) jobs")
        for job in response {
            print("   - \(job.title) | Status: '\(job.status.rawValue)' | ID: \(job.id.uuidString.prefix(8))")
        }
        
        return response
    }
    
    func createJob(_ job: Job) async throws -> Job {
        do {
            // Insert the job and get the response
            // Using .select() after insert to get the created record with server-generated values
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
            print("   Job data: id=\(job.id), title=\(job.title), directorId=\(job.directorId)")
            throw error
        }
    }
    
    // MARK: - Applications
    
    func applyToJob(jobId: UUID, portfolioUrl: String) async throws -> Application {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        let application = Application(
            id: UUID(),
            jobId: jobId,
            actorId: userId,
            status: .portfolioSubmitted,
            portfolioUrl: portfolioUrl,
            portfolioSubmittedAt: Date(),
            appliedAt: Date(),
            updatedAt: Date()
        )
        
        let response: Application = try await supabase
            .from("applications")
            .insert(application)
            .single()
            .execute()
            .value
        return response
    }
    
    func fetchMyApplications() async throws -> [Application] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        let response: [Application] = try await supabase
            .from("applications")
            .select()
            .eq("actor_id", value: userId.uuidString)
            .order("applied_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    // MARK: - Task Submissions
    
    func submitTask(
        applicationId: UUID,
        taskId: UUID,
        submissionUrl: String,
        submissionType: TaskSubmission.SubmissionType,
        thumbnailUrl: String? = nil,
        notes: String? = nil
    ) async throws -> TaskSubmission {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        let submission = TaskSubmission(
            id: UUID(),
            applicationId: applicationId,
            taskId: taskId,
            actorId: userId,
            submissionUrl: submissionUrl,
            submissionType: submissionType,
            thumbnailUrl: thumbnailUrl,
            actorNotes: notes,
            status: .submitted,
            submittedAt: Date(),
            reviewedAt: nil
        )
        
        let response: TaskSubmission = try await supabase
            .from("task_submissions")
            .insert(submission)
            .single()
            .execute()
            .value
        return response
    }
    
    // MARK: - File Upload
    
    func uploadFile(
        fileData: Data,
        fileName: String,
        bucket: String,
        folder: String
    ) async throws -> String {
        let path = "\(folder)/\(fileName)"
        
        try await supabase.storage
            .from(bucket)
            .upload(
                path: path,
                file: fileData,
                options: FileOptions(contentType: "video/mp4")
            )
        
        let publicURL = try supabase.storage
            .from(bucket)
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
    
}
