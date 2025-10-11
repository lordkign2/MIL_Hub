import 'dart:math';
import '../../domain/entities/lesson_entity.dart';

/// Provides initial lesson data for the app
class LessonDataProvider {
  static final List<LessonEntity> _lessons = [
    LessonEntity(
      id: '1',
      title: "How to Detect Fake News with AI",
      subtitle: "Learn to detect misinformation online.",
      content:
          "In today's digital world, fake news has become a serious problem. Fake news means false or misleading information shared online that can trick people and cause confusion. It might influence important things like elections or public opinions, and it can even create unnecessary fear or anger. So, how do we stop fake news from spreading? One powerful tool is Artificial Intelligence, or AI for short.\n\nWhat is AI and How Can It Help?AI is a type of smart technology that helps computers understand and analyze information much like humans do. When it comes to fake news, AI acts like a detective. It reads articles, watches videos, and listens to posts on social media to find out if the information is real or fake.\n\nHow Does AI Spot Fake News?\nAI uses special methods to figure out if a news story is true or false:\n⦁	Reading and Understanding Text: AI looks at the words and sentences in stories and tries to understand their meaning.\n⦁	Checking Facts Against Trusted Sources: AI compares information to reliable databases and official sites to verify the facts.\n⦁	Looking for Clues of False Content: It watches for warning signs such as unusual language patterns or quick spreading of the news that might show it is false.\n⦁	Analyzing Images and Videos: AI can also detect if pictures or videos have been altered or are fake.\n\nChallenges AI Still Faces\nDespite being powerful, AI is not perfect. It can sometimes get things wrong because it depends on the information and rules it has been taught. Sometimes the AI itself can have biases, or it might miss some fake news that's cleverly hidden. That's why human fact-checkers are still important. They work alongside AI to make sure the results are accurate.\n\nWhy Must We Combine AI with Digital Literacy?\nStopping fake news isn't just about technology. It's also about teaching people how to think critically online. Digital literacy means understanding how to evaluate information and recognize fake news. By learning these skills, we become less likely to believe or share false information.\n\nHow Can You Help?\n⦁	Always pause and think before sharing any news.\n⦁	Use AI-powered tools or fact-checking websites to verify information.\n⦁	Share only trusted and verified news with your friends and family.\n⦁	Remember, spreading true information helps build a safer and smarter community.\n\nBy combining smart AI technology and strong digital literacy, we can fight misinformation together and make the internet a more reliable place for everyone.",
      icon: "visibility",
      progress: 40,
      questions: [
        QuestionEntity(
          id: '1-1',
          question: "What's the first step when you see a shocking headline?",
          options: [
            "Share it immediately",
            "Check reliable sources",
            "Ignore it completely",
            "Comment without reading",
          ],
          answer: 1,
        ),
        QuestionEntity(
          id: '1-2',
          question: "Which of these is a reliable fact-checking website?",
          options: [
            "Social media comments",
            "Snopes.com",
            "Random blogs",
            "Anonymous forums",
          ],
          answer: 1,
        ),
      ],
      color: "0xFFFF5252", // Red accent as string
    ),
    LessonEntity(
      id: '2',
      title: "The Power of Media Literacy to Fight Fake News",
      subtitle: "Protect yourself from fraud & phishing.",
      content:
          "In today's digital world, fake news is a big problem. Fake news means false or misleading information shared online that can trick people and cause confusion. It can spread fear, influence important decisions, and cause harm. So, how do we protect ourselves and stop fake news from spreading? One strong way is by building media literacy.\n\nWhat is Media Literacy and Why Does It Matter?\nMedia literacy is the ability to understand and use information from different sources like social media, news websites, videos, and more. Being media literate means knowing how to think carefully about what you see or hear online. It helps you ask questions like: Is this true? Where did this information come from? Can I trust the source? Learning media literacy helps you find real facts and avoid falling for fake news.\n\nHow Does Media Literacy Help Fight Fake News?\nMedia literacy teaches us to:\n⦁	Access Information Carefully: Knowing where to find good and reliable sources.\n⦁	Analyze the Message: Looking closely at what the information says, who made it, and why.\n⦁	Evaluate Trustworthiness: Checking if the source is honest and facts are correct.\n⦁	Think Critically: Asking important questions instead of believing everything at first sight.\n⦁	Create Responsibly: Sharing information that is true and helpful.\nWhen you practice these skills, you're better at spotting fake news and protecting yourself and others from being confused or misled.\n\nChallenges We Face With Fake News\nFake news is often made to look real and spread quickly using social media. Sometimes fake news is shared by mistake, but other times it is created on purpose to trick people or influence opinions. This makes it hard for many people to know what to believe. Also, some sources use fake news to make money or push political ideas. This is why media literacy is so important—it gives you the tools to protect yourself.\n\nWhy Media Literacy is Everyone's Responsibility\nMedia literacy is not just for experts; it's for everyone. Because we all use the internet and social media, everyone needs to learn how to check facts and think carefully. Media literacy empowers you to make smart choices online, respect others, and build a safer internet. When more people are media literate, our online communities become stronger and more truthful.\n\nHow Can You Help?\n⦁	Always pause and think before you believe or share any news.\n⦁	Check if the information comes from trusted sources.\n⦁	Use fact-checking websites to verify stories you find online.\n⦁	Share only news you know is true to help others stay informed.\n⦁	Teach your friends and family about media literacy and fake news.\n\nBy learning and practicing media literacy, we can fight fake news together and make the internet a safer, smarter place for everyone.",
      icon: "shield",
      progress: 20,
      questions: [
        QuestionEntity(
          id: '2-1',
          question: "What is media bias?",
          options: [
            "Neutral reporting",
            "Presenting one perspective more favorably",
            "Accurate information",
            "Educational content",
          ],
          answer: 1,
        ),
      ],
      color: "0xFFFFA726", // Orange accent as string
    ),
    LessonEntity(
      id: '3',
      title: "Teaching Kids Early: How to Spot Fake News",
      subtitle: "Understand framing & media influence.",
      content:
          "In today's world, kids are using the internet and social media more than ever. But not all the news they see online is true. Fake news means false or misleading stories that can trick people and cause confusion. Teaching kids early how to spot fake news helps them stay safe and make smart choices online.\n\nWhy Teach Kids to Spot Fake News?\nKids might believe everything they see or hear online because they are still learning how the world works. Teaching them how to tell real news from fake news helps protect them from being tricked or scared by stories that are not true. It also helps them share good and helpful information with their friends and family.\n\nHow Can Kids Spot Fake News?\nHere are some simple tips to help kids spot fake news:\n⦁	Consider the Source: Teach kids to check where the news comes from. Is it a trusted website or a strange name? Some fake news sites try to look real but use weird website addresses.\n⦁	Look at the Author: Is the article written by a real reporter? If the author is not known or uses a personal email, the story might not be reliable.\n⦁	Check the Date: Sometimes old stories get shared like new ones. Kids should check when the news was published to make sure it's current.\n⦁	Read the Full Story: Headlines can be exciting but may not tell the whole truth. Encourage kids to read the whole article to understand the real message.\n⦁	Watch for Bad Grammar: Many fake news stories have spelling or grammar mistakes. Real news usually has fewer errors.\n⦁	See What Others Say: If no other trusted news sources are sharing the same story, it might be fake. Kids can check websites like ⦁	FactCheck.org to verify.\n⦁	Talk About It: Encourage kids to ask questions and talk about news stories with adults. It helps them think critically and learn more.\n\nChallenges Kids Face\nFake news can be tricky because it is often designed to look real and spread quickly. Kids might see stories that make them feel scared, happy, or angry, and want to share them right away. Teaching kids to stop and think before sharing news is an important skill.\n\nHow Parents and Teachers Can Help\nAdults can support kids by:\n⦁	Talking regularly about fake news and how to spot it.\n⦁	Using games and activities to make learning about fake news fun.\n⦁	Encouraging kids to use trusted news and fact-checking websites.\n⦁	Being open for questions and discussions without judgment.\n\nBy teaching kids early how to spot fake news, we help them become smart and safe users of the internet who can protect themselves and others from false information.\n\nWould you like me to prepare more blog posts on the other topics in a similar style?Here is a blog draft titled \"Teaching Kids Early: How to Spot Fake News\" following your preferred pattern and easy-to-understand language:",
      icon: "balance",
      progress: 60,
      questions: [
        QuestionEntity(
          id: '3-1',
          question:
              "At what age should children start learning about media literacy?",
          options: [
            "18 years old",
            "16 years old",
            "As soon as they use digital devices",
            "Only in college",
          ],
          answer: 2,
        ),
        QuestionEntity(
          id: '3-2',
          question: "What's the best way to teach kids about fake news?",
          options: [
            "Scare them about the internet",
            "Use real examples and discussion",
            "Avoid the topic entirely",
            "Let them figure it out alone",
          ],
          answer: 1,
        ),
      ],
      color: "0xFF66BB6A", // Teal accent as string
    ),
  ];

  /// Get all lessons
  static List<LessonEntity> getAllLessons() {
    return List<LessonEntity>.from(_lessons);
  }

  /// Get a lesson by ID
  static LessonEntity? getLessonById(String id) {
    try {
      return _lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get random lessons for testing
  static List<LessonEntity> getRandomLessons({int count = 3}) {
    final random = Random();
    final lessons = List<LessonEntity>.from(_lessons);
    lessons.shuffle(random);
    return lessons.take(min(count, lessons.length)).toList();
  }
}
